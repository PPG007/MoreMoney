package com.github.ppg007.moremoney.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CategoryDao {
  @Query("SELECT * FROM category_group ORDER BY sort ASC, name ASC")
  fun observeGroups(): Flow<List<CategoryGroupEntity>>

  @Query("SELECT * FROM category_group ORDER BY sort ASC, name ASC")
  suspend fun listGroups(): List<CategoryGroupEntity>

  @Query("SELECT * FROM category_group WHERE id = :id")
  suspend fun getGroup(id: String): CategoryGroupEntity?

  @Query("SELECT * FROM category ORDER BY archived ASC, pinyin ASC, sort ASC")
  fun observeAll(): Flow<List<CategoryEntity>>

  @Query("SELECT * FROM category WHERE group_id = :groupId ORDER BY archived ASC, pinyin ASC, sort ASC")
  fun observeByGroup(groupId: String): Flow<List<CategoryEntity>>

  @Query("SELECT * FROM category WHERE group_id = :groupId ORDER BY archived ASC, pinyin ASC, sort ASC")
  suspend fun listByGroup(groupId: String): List<CategoryEntity>

  @Query("SELECT * FROM category ORDER BY archived ASC, pinyin ASC, sort ASC")
  suspend fun list(): List<CategoryEntity>

  @Query("SELECT * FROM category WHERE id = :id")
  suspend fun get(id: String): CategoryEntity?

  @Query("SELECT * FROM category WHERE name = :name AND archived = 0 ORDER BY sort ASC LIMIT 1")
  suspend fun findByName(name: String): CategoryEntity?

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insert(category: CategoryEntity)

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  suspend fun insertIgnore(category: CategoryEntity)

  @Update
  suspend fun update(category: CategoryEntity)

  @Query("UPDATE category SET archived = 1 WHERE id = :id")
  suspend fun archive(id: String)

  @Query("UPDATE category SET archived = 0 WHERE id = :id")
  suspend fun unarchive(id: String)

  @Query("DELETE FROM category WHERE id = :id")
  suspend fun deleteById(id: String)

  @Query("SELECT COUNT(*) FROM txn WHERE category_id = :categoryId")
  suspend fun countTxns(categoryId: String): Int

  @Query(
    "SELECT c.* FROM category c INNER JOIN txn t ON t.category_id = c.id " +
      "WHERE t.deleted_at IS NULL AND t.occurred_at >= :sinceMs AND c.archived = 0 " +
      "GROUP BY c.id ORDER BY COUNT(t.id) DESC, c.pinyin ASC, c.sort ASC LIMIT :limit",
  )
  suspend fun listFrequent(limit: Int, sinceMs: Long): List<CategoryEntity>

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insertGroup(group: CategoryGroupEntity)

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  suspend fun insertGroupIgnore(group: CategoryGroupEntity)

  @Query("UPDATE category_group SET name = :name WHERE id = :id")
  suspend fun renameGroup(id: String, name: String)

  @Query("DELETE FROM category_group WHERE id = :id")
  suspend fun deleteGroupById(id: String)

  @Query("SELECT COUNT(*) FROM category WHERE group_id = :groupId")
  suspend fun countByGroup(groupId: String): Int

  @Query("SELECT COUNT(*) FROM category")
  suspend fun countAll(): Int

  @Query("DELETE FROM category")
  suspend fun deleteAllCategories()

  @Query("DELETE FROM category_group")
  suspend fun deleteAllGroups()
}
