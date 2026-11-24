package com.github.ppg007.moremoney.data.db

import com.github.ppg007.moremoney.data.db.entity.AppMetaEntity
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.ui.theme.SeedColors

/**
 * 幂等种子数据：固定 ID + `INSERT OR IGNORE`，连续启动不会重复写入。
 *
 * 固定 ID 与名称是数据约定的一部分，导入/导出与测试依赖这些值。
 */
object SeedData {
  const val SEED_VERSION = 1

  suspend fun ensureSeeded(db: MoreMoneyDatabase) {
    val metaDao = db.appMetaDao()
    val current = metaDao.get("seed_version")?.toIntOrNull() ?: 0
    if (current >= SEED_VERSION) {
      return
    }
    val now = System.currentTimeMillis()
    insertBooks(db, now)
    insertGroups(db)
    insertCategories(db, now)
    metaDao.put(AppMetaEntity("seed_version", SEED_VERSION.toString()))
    metaDao.put(AppMetaEntity("schema_version", "2"))
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
        Seed("cat_food", "group_food", "餐饮", "ic_cat_food", SeedColors.c2, "canyin", 0),
        Seed("cat_transport", "group_travel", "交通", "ic_cat_transport", SeedColors.c1, "jiaotong", 0),
        Seed("cat_home", "group_home", "居家", "ic_cat_home", SeedColors.c3, "jujia", 0),
        Seed("cat_shopping", "group_shop", "购物", "ic_cat_shopping", SeedColors.c5, "gouwu", 0),
        Seed("cat_entertain", "group_leisure", "娱乐", "ic_cat_entertain", SeedColors.c4, "yule", 0),
        Seed("cat_medical", "group_other", "医疗", "ic_cat_medical", SeedColors.c8, "yiliao", 0),
        Seed("cat_study", "group_other", "学习", "ic_cat_study", SeedColors.c6, "xuexi", 1),
        Seed("cat_water", "group_home", "水电", "ic_cat_water", SeedColors.c7, "shuidian", 1),
        Seed("cat_phone", "group_other", "通讯", "ic_cat_phone", SeedColors.neutral, "tongxun", 2),
        Seed("cat_other", "group_other", "其他", "ic_cat_other", SeedColors.neutral, "qita", 3),
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
