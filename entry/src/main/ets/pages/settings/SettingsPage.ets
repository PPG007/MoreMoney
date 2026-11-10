import { bundleManager, ConfigurationConstant } from '@kit.AbilityKit';
import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { SettingsService } from '../../service/SettingsService';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';
import { BookManageParam } from '../../models/NavParams';
import { ListRow } from '../../components/base/ListRow';
import { BackupStatusCard } from '../data/BackupStatusCard';

@ComponentV2
export struct SettingsPage {
  @Param stack: NavPathStack = new NavPathStack();
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local lastBackupAt: number = 0;
  @Local lastName: string = '';
  @Local version: string = '1.0.0';
  @Local weekStart: number = 1;
  @Local showWeekSheet: boolean = false;
  @Local appearance: number = 0;
  @Local showAppearanceSheet: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    this.lastBackupAt = SettingsService.lastBackupAt();
    this.lastName = SettingsService.lastBackupName();
    this.weekStart = SettingsService.weekStart();
    this.appearance = SettingsService.appearance();
    try {
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(0);
      this.version = info.versionName;
    } catch (error) {
      this.version = '1.0.0';
    }
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private openData(): void {
    this.stack.pushPathByName('DataBackup', '', (popInfo: PopInfo) => {
      this.reload();
    });
  }

  private openBooks(filterPrivate: boolean): void {
    const param: BookManageParam = new BookManageParam();
    param.filterPrivate = filterPrivate;
    this.stack.pushPathByName('BookManage', param, (popInfo: PopInfo) => {
      this.reload();
    });
  }

  private async chooseWeekStart(value: number): Promise<void> {
    this.weekStart = value;
    this.showWeekSheet = false;
    await SettingsService.setWeekStart(value);
    SnackBarService.show(SettingsPage.toast(value === 1 ? '周起始日已设为周一' : '周起始日已设为周日'));
  }

  private appearanceLabel(): string {
    if (this.appearance === 1) {
      return '浅色';
    }
    if (this.appearance === 2) {
      return '深色';
    }
    return '跟随系统';
  }

  private chooseAppearance(value: number): void {
    const labels: string[] = ['跟随系统', '浅色', '深色'];
    const label: string = labels[value];
    this.appearance = value;
    this.showAppearanceSheet = false;
    SettingsService.setAppearance(value).catch(() => {
    });
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
      if (value === 1) {
        colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      } else if (value === 2) {
        colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      }
      try {
        context.getApplicationContext().setColorMode(colorMode);
      } catch (error) {
      }
      if (value === 1) {
        this.ui.isDark = false;
      } else if (value === 2) {
        this.ui.isDark = true;
      }
    }
    SnackBarService.show(SettingsPage.toast('外观已设为'.concat(label)));
  }

  private showAbout(): void {
    AlertDialog.show({
      title: '关于 MoreMoney',
      message: 'MoreMoney 是一款离线记账应用。\n版本 '.concat(this.version)
        .concat('\n所有数据仅保存在本机。'),
      primaryButton: {
        value: '知道了',
        action: () => {
        }
      }
    });
  }

  @Builder
  sectionLabel(text: string) {
    Text(text)
      .fontSize(AppFont.micro)
      .fontWeight(AppFont.bold)
      .fontColor($r('app.color.ink_3'))
      .letterSpacing(1.2)
      .width('100%')
      .padding({ left: 2 })
  }

  @Builder
  weekSheet() {
    if (this.showWeekSheet) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.showWeekSheet = false;
          })
        Column({ space: Space.x2 }) {
          Text('周起始日')
            .fontSize(AppFont.subTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')
            .padding({ bottom: 6 })
          Row() {
            Text('周一')
              .fontSize(AppFont.row)
              .fontWeight(AppFont.medium)
              .fontColor(this.weekStart === 1 ? $r('app.color.brand_ink') : $r('app.color.ink'))
              .layoutWeight(1)
            if (this.weekStart === 1) {
              Image($r('app.media.ic_check'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.brand_ink'))
            }
          }
          .width('100%')
          .height(50)
          .padding({ left: 13, right: 13 })
          .borderRadius(Radius.input)
          .backgroundColor($r('app.color.surface_2'))
          .onClick(() => {
            this.chooseWeekStart(1);
          })
          Row() {
            Text('周日')
              .fontSize(AppFont.row)
              .fontWeight(AppFont.medium)
              .fontColor(this.weekStart === 7 ? $r('app.color.brand_ink') : $r('app.color.ink'))
              .layoutWeight(1)
            if (this.weekStart === 7) {
              Image($r('app.media.ic_check'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.brand_ink'))
            }
          }
          .width('100%')
          .height(50)
          .padding({ left: 13, right: 13 })
          .borderRadius(Radius.input)
          .backgroundColor($r('app.color.surface_2'))
          .onClick(() => {
            this.chooseWeekStart(7);
          })
        }
        .width('100%')
        .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  appearanceSheet() {
    if (this.showAppearanceSheet) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.showAppearanceSheet = false;
          })
        Column({ space: Space.x2 }) {
          Text('外观')
            .fontSize(AppFont.subTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')
            .padding({ bottom: 6 })
          Row() {
            Text('跟随系统')
              .fontSize(AppFont.row)
              .fontWeight(AppFont.medium)
              .fontColor(this.appearance === 0 ? $r('app.color.brand_ink') : $r('app.color.ink'))
              .layoutWeight(1)
            if (this.appearance === 0) {
              Image($r('app.media.ic_check'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.brand_ink'))
            }
          }
          .width('100%')
          .height(50)
          .padding({ left: 13, right: 13 })
          .borderRadius(Radius.input)
          .backgroundColor($r('app.color.surface_2'))
          .onClick(() => {
            this.chooseAppearance(0);
          })
          Row() {
            Text('浅色')
              .fontSize(AppFont.row)
              .fontWeight(AppFont.medium)
              .fontColor(this.appearance === 1 ? $r('app.color.brand_ink') : $r('app.color.ink'))
              .layoutWeight(1)
            if (this.appearance === 1) {
              Image($r('app.media.ic_check'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.brand_ink'))
            }
          }
          .width('100%')
          .height(50)
          .padding({ left: 13, right: 13 })
          .borderRadius(Radius.input)
          .backgroundColor($r('app.color.surface_2'))
          .onClick(() => {
            this.chooseAppearance(1);
          })
          Row() {
            Text('深色')
              .fontSize(AppFont.row)
              .fontWeight(AppFont.medium)
              .fontColor(this.appearance === 2 ? $r('app.color.brand_ink') : $r('app.color.ink'))
              .layoutWeight(1)
            if (this.appearance === 2) {
              Image($r('app.media.ic_check'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.brand_ink'))
            }
          }
          .width('100%')
          .height(50)
          .padding({ left: 13, right: 13 })
          .borderRadius(Radius.input)
          .backgroundColor($r('app.color.surface_2'))
          .onClick(() => {
            this.chooseAppearance(2);
          })
        }
        .width('100%')
        .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: Space.x4 }) {
          Text('设置')
            .fontSize(AppFont.pageTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')

          BackupStatusCard({
            lastBackupAt: this.lastBackupAt,
            lastName: this.lastName,
            actionLabel: '去备份',
            onTap: () => {
              this.openData();
            }
          })

          Column({ space: Space.x2 }) {
            this.sectionLabel('数据')
            Column() {
              ListRow({
                icon: $r('app.media.ic_book'),
                title: '账本管理',
                subtitle: '新建、编辑、设默认与归档',
                onTap: () => {
                  this.openBooks(false);
                }
              })
              Divider().color($r('app.color.line'))
              ListRow({
                icon: $r('app.media.ic_cat_other'),
                title: '分类管理',
                subtitle: '常用分类与分组',
                onTap: () => {
                  this.stack.pushPathByName('CategoryManage', '');
                }
              })
              Divider().color($r('app.color.line'))
              ListRow({
                icon: $r('app.media.ic_file'),
                title: '数据与备份',
                subtitle: '导入、导出、备份与恢复',
                onTap: () => {
                  this.openData();
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
            this.sectionLabel('隐私')
            Column() {
              ListRow({
                icon: $r('app.media.ic_lock'),
                title: '私密账本',
                subtitle: '只显示私密账本',
                onTap: () => {
                  this.openBooks(true);
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
            this.sectionLabel('通用')
            Column() {
              ListRow({
                icon: $r('app.media.ic_calendar'),
                title: '周起始日',
                trailingText: this.weekStart === 1 ? '周一' : '周日',
                onTap: () => {
                  this.showWeekSheet = true;
                }
              })
              Divider().color($r('app.color.line'))
              ListRow({
                icon: $r('app.media.ic_eye'),
                title: '外观',
                trailingText: this.appearanceLabel(),
                onTap: () => {
                  this.showAppearanceSheet = true;
                }
              })
              Divider().color($r('app.color.line'))
              ListRow({
                icon: $r('app.media.ic_cloud'),
                title: '关于',
                trailingText: this.version,
                onTap: () => {
                  this.showAbout();
                }
              })
            }
            .width('100%')
            .borderRadius(Radius.card)
            .backgroundColor($r('app.color.surface'))
            .border({ width: 1, color: $r('app.color.line') })
          }
          .width('100%')

          Text('MoreMoney '.concat(this.version))
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: Space.x3, bottom: Space.x8 })
        }
        .width('100%')
        .padding({ left: Space.page, right: Space.page, top: this.ui.topInset + 10 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)

      this.weekSheet()
      this.appearanceSheet()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg'))
  }
}
