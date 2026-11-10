import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SQL_CREATE_INDEXES, SQL_CREATE_TABLES, SQL_MIGRATE_BUDGET_PERIODS } from './Schema';
import { SeedData } from './SeedData';

const DOMAIN: number = 0x0001;
const TAG: string = 'MoreMoneyDb';
const DB_NAME: string = 'moremoney.db';
const SCHEMA_VERSION: number = 3;

export class DbManager {
  private static storeInstance: relationalStore.RdbStore | null = null;
  private static initPromise: Promise<void> | null = null;

  static async init(context: Context): Promise<void> {
    if (DbManager.storeInstance !== null) {
      return;
    }
    if (DbManager.initPromise !== null) {
      await DbManager.initPromise;
      return;
    }
    const pending: Promise<void> = DbManager.open(context);
    DbManager.initPromise = pending;
    try {
      await pending;
    } finally {
      DbManager.initPromise = null;
    }
  }

  static get store(): relationalStore.RdbStore {
    if (DbManager.storeInstance === null) {
      throw new Error('DbManager is not initialized');
    }
    return DbManager.storeInstance;
  }

  static isReady(): boolean {
    return DbManager.storeInstance !== null;
  }

  private static async open(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
    await DbManager.migrate(store);
    await SeedData.ensureSeeded(store);
    DbManager.storeInstance = store;
    hilog.info(DOMAIN, TAG, 'DB ready, version=%{public}d', store.version);
  }

  private static async migrate(store: relationalStore.RdbStore): Promise<void> {
    if (store.version < SCHEMA_VERSION) {
      for (const sql of SQL_CREATE_TABLES) {
        await store.executeSql(sql);
      }
      for (const sql of SQL_CREATE_INDEXES) {
        await store.executeSql(sql);
      }
      for (const sql of SQL_MIGRATE_BUDGET_PERIODS) {
        await store.executeSql(sql);
      }
      store.version = SCHEMA_VERSION;
      await SeedData.writeMeta(store, 'schema_version', SCHEMA_VERSION.toString());
    }
  }

  static async getMeta(key: string): Promise<string> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT value FROM app_meta WHERE key = ?', [key]
    );
    try {
      if (rs.goToFirstRow()) {
        return rs.getString(rs.getColumnIndex('value'));
      }
    } finally {
      rs.close();
    }
    return '';
  }

  static async setMeta(key: string, value: string): Promise<void> {
    await SeedData.writeMeta(DbManager.store, key, value);
  }
}
