package com.github.ppg007.moremoney.data.repository

import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import kotlinx.coroutines.flow.Flow

/** 分类与分组仓库；被引用时只允许归档，系统分组不可删除。 */
class CategoryRepository(private val db: MoreMoneyDatabase) {
  private val dao = db.categoryDao()

  fun observeGroups(): Flow<List<CategoryGroupEntity>> = dao.observeGroups()

  fun observeAll(): Flow<List<CategoryEntity>> = dao.observeAll()

  fun observeByGroup(groupId: String): Flow<List<CategoryEntity>> = dao.observeByGroup(groupId)

  suspend fun listGroups(): List<CategoryGroupEntity> = dao.listGroups()

  suspend fun list(): List<CategoryEntity> = dao.list()

  suspend fun listByGroup(groupId: String): List<CategoryEntity> = dao.listByGroup(groupId)

  suspend fun get(id: String): CategoryEntity? = dao.get(id)

  suspend fun findByNames(name: String): CategoryEntity? = dao.findByName(name)

  suspend fun save(category: CategoryEntity) {
    if (dao.get(category.id) == null) {
      dao.insert(category)
    } else {
      dao.update(category)
    }
  }

  suspend fun insertIgnore(category: CategoryEntity) = dao.insertIgnore(category)

  suspend fun archive(id: String) = dao.archive(id)

  suspend fun unarchive(id: String) = dao.unarchive(id)

  suspend fun delete(category: CategoryEntity) {
    if (dao.countTxns(category.id) > 0) {
      throw IllegalStateException("该分类已有流水，请使用归档")
    }
    dao.deleteById(category.id)
  }

  suspend fun countTxns(id: String): Int = dao.countTxns(id)

  suspend fun listFrequent(limit: Int, sinceMs: Long): List<CategoryEntity> = dao.listFrequent(limit, sinceMs)

  suspend fun insertGroup(group: CategoryGroupEntity) = dao.insertGroup(group)

  suspend fun insertGroupIgnore(group: CategoryGroupEntity) = dao.insertGroupIgnore(group)

  suspend fun renameGroup(id: String, name: String) {
    val group = dao.getGroup(id) ?: return
    if (group.isSystem) {
      throw IllegalStateException("系统分组不可重命名")
    }
    dao.renameGroup(id, name)
  }

  suspend fun deleteGroup(id: String) {
    val group = dao.getGroup(id) ?: return
    if (group.isSystem) {
      throw IllegalStateException("系统分组不可删除")
    }
    if (dao.countByGroup(id) > 0) {
      throw IllegalStateException("分组下还有分类，无法删除")
    }
    dao.deleteGroupById(id)
  }

  suspend fun getGroup(id: String): CategoryGroupEntity? = dao.getGroup(id)

  suspend fun countAll(): Int = dao.countAll()
}
