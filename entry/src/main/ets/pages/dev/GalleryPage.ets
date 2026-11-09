import { AppFont, Radius, Space } from '../../theme/Theme';
import { BarColors, chartColors, MemberColors, memberColors, withAlpha } from '../../theme/Palette';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { AppCard } from '../../components/base/AppCard';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { SecondaryButton } from '../../components/base/SecondaryButton';
import { IconButton } from '../../components/base/IconButton';
import { EyeButton } from '../../components/base/EyeButton';
import { AppBadge, BadgeTone } from '../../components/base/Badge';
import { SectionHeader } from '../../components/base/SectionHeader';
import { ListRow } from '../../components/base/ListRow';
import { ToggleRow } from '../../components/base/ToggleRow';
import { EmptyState } from '../../components/base/EmptyState';
import { SegmentedControl } from '../../components/base/SegmentedControl';
import { AmountBar, AmountTone } from '../../components/base/AmountBar';
import { MemberDot } from '../../components/base/MemberDot';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { SnackBarService, SnackBarOptions } from '../../service/SnackBarService';
import { DebugSeedService } from '../../service/DebugSeedService';
import { DateUtil } from '../../utils/DateUtil';
import { formatCents } from '../../utils/MoneyUtil';

class ColorSample {
  label: string = '';
  value: ResourceColor = Color.Transparent;
}

class FontSample {
  label: string = '';
  size: number = 10;
}

@Preview
@ComponentV2
export struct GalleryPage {
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local segment: number = 0;
  @Local snackCount: number = 0;

  private colorSamples(): ColorSample[] {
    const list: ColorSample[] = [];
    GalleryPage.addColor(list, 'bg', $r('app.color.bg'));
    GalleryPage.addColor(list, 'surface', $r('app.color.surface'));
    GalleryPage.addColor(list, 'surface_2', $r('app.color.surface_2'));
    GalleryPage.addColor(list, 'surface_3', $r('app.color.surface_3'));
    GalleryPage.addColor(list, 'ink', $r('app.color.ink'));
    GalleryPage.addColor(list, 'ink_2', $r('app.color.ink_2'));
    GalleryPage.addColor(list, 'ink_3', $r('app.color.ink_3'));
    GalleryPage.addColor(list, 'line', $r('app.color.line'));
    GalleryPage.addColor(list, 'brand', $r('app.color.brand'));
    GalleryPage.addColor(list, 'brand_ink', $r('app.color.brand_ink'));
    GalleryPage.addColor(list, 'brand_soft', $r('app.color.brand_soft'));
    GalleryPage.addColor(list, 'brand_wash', $r('app.color.brand_wash'));
    GalleryPage.addColor(list, 'btn_bg', $r('app.color.btn_bg'));
    GalleryPage.addColor(list, 'expense', $r('app.color.expense'));
    GalleryPage.addColor(list, 'good', $r('app.color.good'));
    GalleryPage.addColor(list, 'warn', $r('app.color.warn'));
    return list;
  }

  private static addColor(list: ColorSample[], label: string, value: ResourceColor): void {
    const sample: ColorSample = new ColorSample();
    sample.label = label;
    sample.value = value;
    list.push(sample);
  }

  private fontSamples(): FontSample[] {
    const list: FontSample[] = [];
    GalleryPage.addFont(list, '10 微标签', AppFont.micro);
    GalleryPage.addFont(list, '11 图例', AppFont.legend);
    GalleryPage.addFont(list, '12 设置', AppFont.settings);
    GalleryPage.addFont(list, '13 流水', AppFont.row);
    GalleryPage.addFont(list, '14 区块', AppFont.body);
    GalleryPage.addFont(list, '17 二级页标题', AppFont.subTitle);
    GalleryPage.addFont(list, '23 饼图中心', AppFont.donutCenter);
    GalleryPage.addFont(list, '25 一级页标题', AppFont.pageTitle);
    GalleryPage.addFont(list, '32 月份', AppFont.month);
    GalleryPage.addFont(list, '42 本月支出', AppFont.heroAmount);
    return list;
  }

  private static addFont(list: FontSample[], label: string, size: number): void {
    const sample: FontSample = new FontSample();
    sample.label = label;
    sample.size = size;
    list.push(sample);
  }

  private showSnackBar(): void {
    this.snackCount += 1;
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = '已删除 1 笔流水（第 ' + this.snackCount.toString() + ' 条提示）';
    options.actionLabel = '撤销';
    options.onAction = () => {
      this.snackCount = 0;
    };
    SnackBarService.show(options);
  }

  private seedDemo(): void {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    DebugSeedService.seedDemo(context).then(() => {
      const options: SnackBarOptions = new SnackBarOptions();
      options.message = '演示数据已写入';
      SnackBarService.show(options);
    }).catch(() => {
      const options: SnackBarOptions = new SnackBarOptions();
      options.message = '演示数据写入失败';
      SnackBarService.show(options);
    });
  }

  build() {
    Scroll() {
      Column({ space: Space.x6 }) {
        Row({ space: Space.x3 }) {
          Text('组件样例')
            .fontSize(AppFont.pageTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .layoutWeight(1)
          EyeButton()
        }
        .width('100%')

        Text('今天是 ' + DateUtil.formatDayCn(DateUtil.dayKey(new Date())))
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))

        SectionHeader({ title: '颜色 Token' })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.colorSamples(), (sample: ColorSample) => {
            Column({ space: 3 }) {
              Row()
                .width(44)
                .height(30)
                .borderRadius(8)
                .backgroundColor(sample.value)
                .border({ width: 1, color: $r('app.color.line') })
              Text(sample.label)
                .fontSize(9)
                .fontColor($r('app.color.ink_3'))
            }
            .margin({ right: Space.x2, bottom: Space.x2 })
          }, (sample: ColorSample) => sample.label)
        }
        .width('100%')

        SectionHeader({ title: '字号阶梯' })
        Column({ space: Space.x2 }) {
          ForEach(this.fontSamples(), (sample: FontSample) => {
            Row({ space: Space.x3 }) {
              Text(sample.label)
                .fontSize(AppFont.caption)
                .fontColor($r('app.color.ink_3'))
                .width(96)
              Text('¥1,286.40')
                .fontSize(sample.size)
                .fontWeight(AppFont.semibold)
                .fontColor($r('app.color.ink'))
                .fontFeature(AppFont.tnum)
            }
            .width('100%')
          }, (sample: FontSample) => sample.label)
        }
        .width('100%')

        SectionHeader({ title: '按钮三态' })
        Column({ space: Space.x3 }) {
          PrimaryButton({ label: '保存' })
          PrimaryButton({ label: '禁用态', isEnabled: false })
          SecondaryButton({ label: '取消' })
          Row({ space: Space.x3 }) {
            IconButton({ icon: $r('app.media.ic_plus') })
            IconButton({ icon: $r('app.media.ic_search'), tint: $r('app.color.brand_ink') })
            EyeButton()
          }
        }
        .width('100%')

        SectionHeader({ title: '卡片与徽标' })
        AppCard({ contentPadding: 16 }) {
          Column({ space: Space.x3 }) {
            Row({ space: Space.x2 }) {
              AppBadge({ text: '默认' })
              AppBadge({ text: '私密', tone: BadgeTone.Warn })
              MemberDot({ initial: '自', color: memberColors(this.ui.isDark).self })
              MemberDot({ initial: '家', color: memberColors(this.ui.isDark).family })
            }
            Text('卡片内容使用 surface、line 76% 与 Shadow.card')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }

        SectionHeader({ title: '列表与开关' })
        Column() {
          ListRow({ title: '账本管理', subtitle: '3 个账本', icon: $r('app.media.ic_book') })
          Divider().color($r('app.color.line'))
          ToggleRow({
            title: '隐藏金额',
            subtitle: '仅当前会话有效',
            isOn: this.ui.hideAmount,
            onChange: (isOn: boolean) => {
              this.ui.hideAmount = isOn;
            }
          })
        }
        .width('100%')
        .borderRadius(Radius.card)
        .backgroundColor($r('app.color.surface'))

        SectionHeader({ title: '空状态' })
        EmptyState({
          icon: $r('app.media.ic_file'),
          title: '还没有流水',
          description: '点右下角开始记一笔',
          actionLabel: '去记账'
        })

        SectionHeader({ title: '分段与进度' })
        Column({ space: Space.x3 }) {
          SegmentedControl({
            options: ['分类', '趋势', '日历'],
            selectedIndex: this.segment,
            onChange: (index: number) => {
              this.segment = index;
            }
          })
          AmountBar({ percent: 0.62 })
          AmountBar({ percent: 0.88, tone: AmountTone.Expense })
          AmountBar({ percent: 1, tone: AmountTone.Good })
        }
        .width('100%')

        SectionHeader({ title: '金额文本' })
        Column({ space: Space.x2 }) {
          MoneyText({ cents: 128640, fontSize: AppFont.heroAmount, tone: MoneyTone.Expense })
          MoneyText({ cents: 128640, fontSize: AppFont.subTitle })
          MoneyText({ cents: 0, fontSize: AppFont.body, tone: MoneyTone.Good, signed: true })
          MoneyText({ cents: 128640, fontSize: AppFont.body, locked: true })
          MoneyText({ cents: 128640, fontSize: AppFont.body, forceVisible: true })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        SectionHeader({ title: '提示条与调试' })
        Column({ space: Space.x3 }) {
          PrimaryButton({
            label: '显示 SnackBar',
            onTap: () => {
              this.showSnackBar();
            }
          })
          SecondaryButton({
            label: '写入演示数据',
            onTap: () => {
              this.seedDemo();
            }
          })
          Text('当前 ChartColors.other = ' + chartColors(this.ui.isDark).other)
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
        }
        .width('100%')

        Row({ space: Space.x2 }) {
          Text('成员色')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
          ForEach(GalleryPage.memberKeys(), (key: string) => {
            Row()
              .width(18)
              .height(18)
              .borderRadius(9)
              .backgroundColor(this.memberColor(key))
          }, (key: string) => key)
        }
        .width('100%')

        Text('Bar ' + BarColors.statusBarLight + ' / ' +
          withAlpha(memberColors(this.ui.isDark).self, 0.2) + ' / ' + formatCents(123456))
          .fontSize(8)
          .fontColor($r('app.color.ink_3'))
      }
      .width('100%')
      .padding({
        left: Space.page,
        right: Space.page,
        top: this.ui.topInset + Space.x4,
        bottom: Space.x8
      })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg'))
    .scrollBar(BarState.Off)
  }

  private static memberKeys(): string[] {
    return ['self', 'family', 'child'];
  }

  private memberColor(key: string): string {
    const colors: MemberColors = memberColors(this.ui.isDark);
    if (key === 'family') {
      return colors.family;
    }
    if (key === 'child') {
      return colors.child;
    }
    return colors.self;
  }
}
