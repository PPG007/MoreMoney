import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { Book, Member, TxnFilter } from '../../models/Entities';
import { NavResult } from '../../models/NavParams';
import { BookDao } from '../../data/db/BookDao';
import { MemberDao } from '../../data/db/MemberDao';
import { TxnDao } from '../../data/db/TxnDao';
import { SettingsService } from '../../service/SettingsService';
import { PrivateBookService } from '../../service/PrivateBookService';
import { BackupService, RestoreSummary } from '../../service/BackupService';
import { BackupDocument } from '../../service/BackupFormat';
import { CsvExportService } from '../../service/CsvExportService';
import { CsvImportService, ImportPreview } from '../../service/CsvImportService';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { PageHeader } from '../../components/layout/PageHeader';
import { ListRow } from '../../components/base/ListRow';
import { EyeButton } from '../../components/base/EyeButton';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { SecondaryButton } from '../../components/base/SecondaryButton';
import { BackupStatusCard } from './BackupStatusCard';
import { DataStatsCard } from './DataStatsCard';
import { ExportFilterSheet } from '../../components/sheet/ExportFilterSheet';
import { ImportPreviewSheet } from '../../components/sheet/ImportPreviewSheet';
import { RestorePreviewSheet } from '../../components/sheet/RestorePreviewSheet';

@Builder
export function DataBackupBuilder() {
  DataBackupPage();
}

@ComponentV2
export struct DataBackupPage {
  stack: NavPathStack = new NavPathStack();
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local lastBackupAt: number = 0;
  @Local lastName: string = '';
  @Local booksCount: number = 0;
  @Local txnCount: number = 0;
  @Local busy: boolean = false;
  @Local books: Book[] = [];
  @Local members: Member[] = [];
  @Local lockedIds: string[] = [];
  @Local showExport: boolean = false;
  @Local showImport: boolean = false;
  @Local importPreview: ImportPreview | null = null;
  @Local showRestore: boolean = false;
  @Local restoreSummary: RestoreSummary | null = null;
  @Local restoreDoc: BackupDocument | null = null;
  @Local showBackupPwd: boolean = false;
  @Local backupBookIds: string[] = [];
  @Local backupBookNames: string[] = [];
  @Local backupPwd: Record<string, string> = {};

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.lastBackupAt = SettingsService.lastBackupAt();
    this.lastName = SettingsService.lastBackupName();
    try {
      this.books = await BookDao.list();
      this.members = await MemberDao.list();
      this.lockedIds = await PrivateBookService.lockedBookIds();
      this.booksCount = this.books.filter((book: Book): boolean => !book.archived).length;
      const filter: TxnFilter = new TxnFilter();
      this.txnCount = await TxnDao.countRange(filter);
    } catch (error) {
      this.txnCount = 0;
    }
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private context(): Context | undefined {
    return this.getUIContext().getHostContext();
  }

  private startBackup(): void {
    const privateBooks: Book[] = this.books.filter((book: Book): boolean => book.isPrivate);
    if (privateBooks.length === 0) {
      this.doBackup({});
      return;
    }
    const ids: string[] = [];
    const names: string[] = [];
    for (const book of privateBooks) {
      ids.push(book.id);
      names.push(book.name);
    }
    this.backupBookIds = ids;
    this.backupBookNames = names;
    this.backupPwd = {};
    this.showBackupPwd = true;
  }

  private async doBackup(passwords: Record<string, string>): Promise<void> {
    const context: Context | undefined = this.context();
    if (context === undefined) {
      return;
    }
    this.busy = true;
    try {
      const count: number = await BackupService.exportToFile(context, passwords);
      this.showBackupPwd = false;
      if (count >= 0) {
        SnackBarService.show(DataBackupPage.toast('已备份 '.concat(count.toString()).concat(' 笔记录')));
        await this.reload();
      }
    } catch (error) {
      SnackBarService.show(DataBackupPage.toast(ErrorUtil.messageOf(error)));
    } finally {
      this.busy = false;
    }
  }

  private canBackup(): boolean {
    for (const id of this.backupBookIds) {
      const value: string | undefined = this.backupPwd[id];
      if (value === undefined || value.length === 0) {
        return false;
      }
    }
    return !this.busy;
  }

  private async startRestore(): Promise<void> {
    const context: Context | undefined = this.context();
    if (context === undefined) {
      return;
    }
    try {
      const doc: BackupDocument | null = await BackupService.pickAndParse(context);
      if (doc === null) {
        return;
      }
      this.restoreDoc = doc;
      this.restoreSummary = BackupService.summary(doc);
      this.showRestore = true;
    } catch (error) {
      SnackBarService.show(DataBackupPage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async confirmRestore(passwords: Record<string, string>): Promise<void> {
    if (this.restoreDoc === null) {
      return;
    }
    this.busy = true;
    try {
      const count: number = await BackupService.restore(this.restoreDoc, passwords);
      this.showRestore = false;
      this.restoreDoc = null;
      SnackBarService.show(DataBackupPage.toast('已恢复 '.concat(count.toString()).concat(' 笔记录')));
      await this.reload();
    } catch (error) {
      SnackBarService.show(DataBackupPage.toast(ErrorUtil.messageOf(error)));
    } finally {
      this.busy = false;
    }
  }

  private async exportCsv(bookIds: string[], memberIds: string[], startMs: number, endMs: number): Promise<void> {
    const context: Context | undefined = this.context();
    if (context === undefined) {
      return;
    }
    try {
      const filter: TxnFilter = new TxnFilter();
      filter.bookIds = bookIds;
      filter.memberIds = memberIds;
      filter.startMs = startMs;
      filter.endMs = endMs;
      const count: number = await CsvExportService.exportCsv(context, filter, this.lockedIds);
      this.showExport = false;
      if (count >= 0) {
        SnackBarService.show(DataBackupPage.toast('已导出 '.concat(count.toString()).concat(' 笔记录')));
      }
    } catch (error) {
      SnackBarService.show(DataBackupPage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async startImport(): Promise<void> {
    const context: Context | undefined = this.context();
    if (context === undefined) {
      return;
    }
    try {
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.csv'];
      const uris: string[] = await documentPicker.select(options);
      if (uris.length === 0) {
        return;
      }
      const text: string = fileIo.readTextSync(uris[0]);
      this.importPreview = await CsvImportService.preview(text);
      this.showImport = true;
    } catch (error) {
      SnackBarService.show(DataBackupPage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async confirmImport(): Promise<void> {
    if (this.importPreview === null) {
      return;
    }
    this.busy = true;
    try {
      const result = await CsvImportService.execute(this.importPreview);
      this.showImport = false;
      SnackBarService.show(DataBackupPage.toast('导入 '.concat(result.inserted.toString())
        .concat(' 笔，跳过 ').concat(result.skipped.toString()).concat(' 笔重复')));
      await this.reload();
    } catch (error) {
      SnackBarService.show(DataBackupPage.toast(ErrorUtil.messageOf(error)));
    } finally {
      this.busy = false;
    }
  }

  @Builder
  headerTrailing() {
    EyeButton()
  }

  @Builder
  backupPasswordSheet() {
    if (this.showBackupPwd) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.showBackupPwd = false;
          })
        Scroll() {
          Column({ space: Space.x3 }) {
            Row() {
              Text('备份私密账本')
                .fontSize(AppFont.subTitle)
                .fontWeight(AppFont.bold)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
              Text('取消')
                .fontSize(AppFont.settings)
                .fontColor($r('app.color.ink_3'))
                .onClick(() => {
                  this.showBackupPwd = false;
                })
            }
            .width('100%')

            Text('私密账本的数据会使用各自的密码加密后写入备份文件。')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
              .width('100%')

            ForEach(this.backupBookIds, (bookId: string, index: number) => {
              Column({ space: 4 }) {
                Text(this.backupBookNames[index])
                  .fontSize(AppFont.caption)
                  .fontColor($r('app.color.ink_3'))
                  .width('100%')
                TextInput({ text: this.backupPwd[bookId], placeholder: '密码' })
                  .width('100%')
                  .height(44)
                  .type(InputType.Password)
                  .fontSize(AppFont.settings)
                  .fontColor($r('app.color.ink'))
                  .placeholderColor($r('app.color.ink_3'))
                  .backgroundColor($r('app.color.surface_2'))
                  .borderRadius(Radius.input)
                  .onChange((value: string) => {
                    this.backupPwd[bookId] = value;
                  })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }, (bookId: string) => bookId)

            PrimaryButton({
              label: this.busy ? '备份中…' : '开始备份',
              isEnabled: this.canBackup(),
              onTap: () => {
                if (this.canBackup()) {
                  this.doBackup(this.backupPwd);
                }
              }
            })
          }
          .width('100%')
          .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        }
        .constraintSize({ maxHeight: '80%' })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          PageHeader({
            title: '数据与备份',
            onBack: () => {
              this.stack.pop(new NavResult());
            },
            trailing: this.headerTrailing
          })

          Scroll() {
            Column({ space: Space.x3 }) {
              BackupStatusCard({
                lastBackupAt: this.lastBackupAt,
                lastName: this.lastName,
                actionLabel: '立即备份',
                onTap: () => {
                  this.startBackup();
                }
              })

              PrimaryButton({
                label: this.busy ? '处理中…' : '立即备份',
                isEnabled: !this.busy,
                onTap: () => {
                  this.startBackup();
                }
              })

              SecondaryButton({
                label: '从备份恢复',
                isEnabled: !this.busy,
                onTap: () => {
                  this.startRestore();
                }
              })

              Column({ space: Space.x2 }) {
                Text('导入导出')
                  .fontSize(AppFont.micro)
                  .fontWeight(AppFont.bold)
                  .fontColor($r('app.color.ink_3'))
                  .letterSpacing(1.2)
                  .width('100%')
                Column() {
                  ListRow({
                    icon: $r('app.media.ic_file'),
                    title: '导出 CSV',
                    subtitle: '可按日期、账本、成员筛选',
                    onTap: () => {
                      this.showExport = true;
                    }
                  })
                  Divider().color($r('app.color.line'))
                  ListRow({
                    icon: $r('app.media.ic_archive'),
                    title: '导入 CSV',
                    subtitle: '写入前全量校验，错误带行号',
                    onTap: () => {
                      this.startImport();
                    }
                  })
                }
                .width('100%')
                .borderRadius(Radius.card)
                .backgroundColor($r('app.color.surface'))
                .border({ width: 1, color: $r('app.color.line') })
              }
              .width('100%')

              Column({ space: Space.x2 }) {
                Text('数据统计')
                  .fontSize(AppFont.micro)
                  .fontWeight(AppFont.bold)
                  .fontColor($r('app.color.ink_3'))
                  .letterSpacing(1.2)
                  .width('100%')
                DataStatsCard({
                  books: this.booksCount,
                  txns: this.txnCount,
                  sizeText: '—'
                })
              }
              .width('100%')

              Text('恢复会覆盖当前全部数据，且不可撤销。')
                .fontSize(AppFont.caption)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
                .padding({ top: Space.x2, bottom: Space.x8 })
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page, top: Space.x3 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')

        ExportFilterSheet({
          visible: this.showExport,
          books: this.books,
          members: this.members,
          lockedIds: this.lockedIds,
          onExport: (bookIds: string[], memberIds: string[], startMs: number, endMs: number) => {
            this.exportCsv(bookIds, memberIds, startMs, endMs);
          },
          onClose: () => {
            this.showExport = false;
          }
        })

        ImportPreviewSheet({
          visible: this.showImport,
          preview: this.importPreview,
          busy: this.busy,
          onConfirm: () => {
            this.confirmImport();
          },
          onClose: () => {
            this.showImport = false;
          }
        })

        RestorePreviewSheet({
          visible: this.showRestore,
          summary: this.restoreSummary,
          busy: this.busy,
          onConfirm: (passwords: Record<string, string>) => {
            this.confirmRestore(passwords);
          },
          onClose: () => {
            this.showRestore = false;
            this.restoreDoc = null;
          }
        })

        this.backupPasswordSheet()
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
    .onShown(() => {
      this.reload();
    })
    .onReady((context: NavDestinationContext) => {
      this.stack = context.pathStack;
    })
  }
}
