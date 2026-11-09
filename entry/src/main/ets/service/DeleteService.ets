import { TxnDao } from '../data/db/TxnDao';

export class DeleteService {
  static async deleteTxn(txnId: string): Promise<void> {
    await TxnDao.softDelete(txnId);
  }

  static async undoDelete(txnId: string): Promise<void> {
    await TxnDao.restore(txnId);
  }

  static async purgeExpired(): Promise<void> {
    await TxnDao.hardDeleteExpired();
  }
}
