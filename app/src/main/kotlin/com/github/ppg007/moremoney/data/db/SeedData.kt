package com.github.ppg007.moremoney.data.db

import com.github.ppg007.moremoney.data.db.dao.CategoryDao
import com.github.ppg007.moremoney.data.db.entity.AppMetaEntity
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.ui.theme.SeedColors

/**
 * 幂等种子数据：固定 ID + `INSERT OR IGNORE`，连续启动不会重复写入。
 *
 * 固定 ID 与名称是数据约定的一部分，导入/导出与测试依赖这些值。
 *
 * v2 起内置分类为 18 个（饮食、电费、日用、交通、社交、住房物业、停车费、洗车、
 * 礼物、通信、工作、服饰、娱乐、美容、医疗、税金、教育、旅行）。从 v1 升级时，
 * 名称仍为旧默认值的分类会原地重命名（保留 ID 与已有流水的关联）；旧的“其他”
 * 分类不再属于内置列表，未自定义时归档。
 */
object SeedData {
  const val SEED_VERSION = 2

  suspend fun ensureSeeded(db: MoreMoneyDatabase) {
    val metaDao = db.appMetaDao()
    val current = metaDao.get("seed_version")?.toIntOrNull() ?: 0
    if (current >= SEED_VERSION) {
      return
    }
    val now = System.currentTimeMillis()
    insertBooks(db, now)
    insertGroups(db)
    migrateLegacyCategories(db)
    insertCategories(db, now)
    metaDao.put(AppMetaEntity("seed_version", SEED_VERSION.toString()))
    metaDao.put(AppMetaEntity("schema_version", "3"))
  }

  private suspend fun insertBooks(db: MoreMoneyDatabase, now: Long) {
    val dao = db.bookDao()
    dao.insertIgnore(
      BookEntity(
        id = "book_daily", name = "日常账本", icon = "ic_book_daily", color = SeedColors.c1,
        isDefault = true, sort = 0, archived = false, createdAt = now, updatedAt = now,
      )
    )
    dao.insertIgnore(
      BookEntity(
        id = "book_travel", name = "旅行", icon = "ic_book_travel", color = SeedColors.c2,
        isDefault = false, sort = 1, archived = false, createdAt = now, updatedAt = now,
      )
    )
    dao.insertIgnore(
      BookEntity(
        id = "book_repair", name = "装修", icon = "ic_book_repair", color = SeedColors.c3,
        isDefault = false, sort = 2, archived = false, createdAt = now, updatedAt = now,
      )
    )
  }

  private suspend fun insertGroups(db: MoreMoneyDatabase) {
    val dao = db.categoryDao()
    val ids = listOf("group_food", "group_travel", "group_home", "group_shop", "group_leisure", "group_other")
    val names = listOf("餐饮", "出行", "居家", "购物", "休闲", "其他")
    ids.forEachIndexed { index, id ->
      dao.insertGroupIgnore(
        CategoryGroupEntity(id = id, name = names[index], sort = index, isSystem = true)
      )
    }
  }

  /**
   * v1 → v2：把旧内置分类改名为新内置分类。
   *
   * 仅在名称仍等于旧默认值时更新，避免覆盖用户自行修改过的分类；
   * ID 保持不变，历史流水无需迁移。
   */
  private suspend fun migrateLegacyCategories(db: MoreMoneyDatabase) {
    val dao = db.categoryDao()
    migrateLegacy(
      dao = dao,
      id = "cat_food",
      legacyName = "餐饮",
      name = "饮食",
      groupId = "group_food",
      icon = "ic_cat_food",
      color = SeedColors.c2,
      pinyin = "yinshi",
      sort = 0,
    )
    migrateLegacy(
      dao = dao,
      id = "cat_water",
      legacyName = "水电",
      name = "电费",
      groupId = "group_home",
      icon = "ic_cat_power",
      color = SeedColors.c7,
      pinyin = "dianfei",
      sort = 0,
    )
    migrateLegacy(
      dao = dao,
      id = "cat_shopping",
      legacyName = "购物",
      name = "日用",
      groupId = "group_home",
      icon = "ic_cat_shopping",
      color = SeedColors.c5,
      pinyin = "riyong",
      sort = 1,
    )
    migrateLegacy(
      dao = dao,
      id = "cat_home",
      legacyName = "居家",
      name = "住房物业",
      groupId = "group_home",
      icon = "ic_cat_home",
      color = SeedColors.c3,
      pinyin = "zhufangwuye",
      sort = 2,
    )
    migrateLegacy(
      dao = dao,
      id = "cat_phone",
      legacyName = "通讯",
      name = "通信",
      groupId = "group_other",
      icon = "ic_cat_phone",
      color = SeedColors.neutral,
      pinyin = "tongxin",
      sort = 0,
    )
    migrateLegacy(
      dao = dao,
      id = "cat_study",
      legacyName = "学习",
      name = "教育",
      groupId = "group_other",
      icon = "ic_cat_study",
      color = SeedColors.c6,
      pinyin = "jiaoyu",
      sort = 5,
    )

    val legacyOther = dao.get("cat_other")
    if (legacyOther?.name == "其他" && !legacyOther.archived) {
      dao.archive("cat_other")
    }
  }

  private suspend fun migrateLegacy(
    dao: CategoryDao,
    id: String,
    legacyName: String,
    name: String,
    groupId: String,
    icon: String,
    color: String,
    pinyin: String,
    sort: Int,
  ) {
    val current = dao.get(id) ?: return
    if (current.name != legacyName) {
      return
    }
    dao.update(
      current.copy(
        name = name,
        groupId = groupId,
        icon = icon,
        color = color,
        pinyin = pinyin,
        sort = sort,
      )
    )
  }

  private suspend fun insertCategories(db: MoreMoneyDatabase, now: Long) {
    val dao = db.categoryDao()
    data class Seed(
      val id: String,
      val groupId: String,
      val name: String,
      val icon: String,
      val color: String,
      val pinyin: String,
      val sort: Int,
    )

    val list =
      listOf(
        Seed("cat_food", "group_food", "饮食", "ic_cat_food", SeedColors.c2, "yinshi", 0),
        Seed("cat_water", "group_home", "电费", "ic_cat_power", SeedColors.c7, "dianfei", 0),
        Seed("cat_shopping", "group_home", "日用", "ic_cat_shopping", SeedColors.c5, "riyong", 1),
        Seed("cat_transport", "group_travel", "交通", "ic_cat_transport", SeedColors.c1, "jiaotong", 0),
        Seed("cat_social", "group_leisure", "社交", "ic_cat_entertain", SeedColors.c4, "shejiao", 0),
        Seed("cat_home", "group_home", "住房物业", "ic_cat_home", SeedColors.c3, "zhufangwuye", 2),
        Seed("cat_parking", "group_travel", "停车费", "ic_cat_transport", SeedColors.c1, "tingchefei", 1),
        Seed("cat_carwash", "group_travel", "洗车", "ic_cat_water", SeedColors.c7, "xiche", 2),
        Seed("cat_gift", "group_shop", "礼物", "ic_cat_shopping", SeedColors.c5, "liwu", 0),
        Seed("cat_phone", "group_other", "通信", "ic_cat_phone", SeedColors.neutral, "tongxin", 0),
        Seed("cat_work", "group_other", "工作", "ic_cat_repair", SeedColors.c6, "gongzuo", 1),
        Seed("cat_clothing", "group_shop", "服饰", "ic_cat_shopping", SeedColors.c5, "fushi", 1),
        Seed("cat_entertain", "group_leisure", "娱乐", "ic_cat_entertain", SeedColors.c4, "yule", 1),
        Seed("cat_beauty", "group_other", "美容", "ic_cat_other", SeedColors.c5, "meirong", 2),
        Seed("cat_medical", "group_other", "医疗", "ic_cat_medical", SeedColors.c8, "yiliao", 3),
        Seed("cat_tax", "group_other", "税金", "ic_cat_other", SeedColors.neutral, "shuijin", 4),
        Seed("cat_study", "group_other", "教育", "ic_cat_study", SeedColors.c6, "jiaoyu", 5),
        Seed("cat_travel", "group_travel", "旅行", "ic_cat_travel", SeedColors.c2, "lvxing", 3),
      )
    for (seed in list) {
      dao.insertIgnore(
        CategoryEntity(
          id = seed.id,
          groupId = seed.groupId,
          name = seed.name,
          icon = seed.icon,
          color = seed.color,
          pinyin = seed.pinyin,
          sort = seed.sort,
          archived = false,
          createdAt = now,
        )
      )
    }
  }
}
