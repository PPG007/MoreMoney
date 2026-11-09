import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { memberColorOf, withAlpha } from '../../theme/Palette';
import { Member } from '../../models/Entities';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct MemberPickerSheet {
  @Param visible: boolean = false;
  @Param members: Member[] = [];
  @Param selectedId: string = '';
  @Event onSelect: (memberId: string) => void = (memberId: string) => {
  };
  @Event onManage: () => void = () => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.onClose();
          })

        Column({ space: Space.x3 }) {
          Text('选择成员')
            .fontSize(AppFont.subTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')

          ForEach(this.members, (member: Member) => {
            Row({ space: 11 }) {
              Text(member.initial)
                .fontSize(AppFont.caption)
                .fontWeight(AppFont.bold)
                .fontColor(memberColorOf(member.color, this.ui.isDark))
                .textAlign(TextAlign.Center)
                .width(28)
                .height(28)
                .borderRadius(14)
                .backgroundColor(withAlpha(memberColorOf(member.color, this.ui.isDark), 0.15))
              Text(member.name)
                .fontSize(AppFont.row)
                .fontWeight(AppFont.semibold)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
              if (this.selectedId === member.id) {
                Image($r('app.media.ic_check'))
                  .width(16)
                  .height(16)
                  .fillColor($r('app.color.brand_ink'))
              }
            }
            .width('100%')
            .height(52)
            .padding({ left: 12, right: 12 })
            .borderRadius(Radius.input)
            .backgroundColor(this.selectedId === member.id ? $r('app.color.brand_wash') : Color.Transparent)
            .onClick(() => {
              this.onSelect(member.id);
            })
          }, (member: Member) => member.id)

          Row() {
            Text('管理成员')
              .fontSize(AppFont.settings)
              .fontWeight(AppFont.semibold)
              .fontColor($r('app.color.brand_ink'))
          }
          .width('100%')
          .height(44)
          .justifyContent(FlexAlign.Center)
          .borderRadius(Radius.input)
          .backgroundColor($r('app.color.brand_wash'))
          .onClick(() => {
            this.onManage();
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
}
