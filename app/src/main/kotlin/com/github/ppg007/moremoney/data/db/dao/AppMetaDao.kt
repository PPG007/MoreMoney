package com.github.ppg007.moremoney.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.github.ppg007.moremoney.data.db.entity.AppMetaEntity

@Dao
interface AppMetaDao {
  @Query("SELECT value FROM app_meta WHERE key = :key LIMIT 1")
  suspend fun get(key: String): String?

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun put(meta: AppMetaEntity)

  @Query("DELETE FROM app_meta WHERE key = :key")
  suspend fun remove(key: String)
}
