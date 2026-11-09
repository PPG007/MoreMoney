import { AppFont, Radius } from '../../theme/Theme';

@ComponentV2
export struct BackupStatusCard {
  @Param lastBackupAt: number = 0;
  @Param lastName: string = '';
  @Param actionLabel: string = '去备份';
  @Event onTap: () => void = () => {
  };

  private timeText(): string {
    if (this.lastBackupAt <= 0) {
      return '从未备份';
    }
    const date: Date = new Date(this.lastBackupAt);
    return (date.getMonth() + 1).toString().concat('月').concat(date.getDate().toString()).concat('日 ')
      .concat(CsvTime.pad(date.getHours())).concat(':').concat(CsvTime.pad(date.getMinutes()));
  }

  build() {
    Row({ space: 11 }) {
      Stack() {
        Image($r('app.media.ic_cloud'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.brand_ink'))
      }
      .width(39)
      .height(39)
      .borderRadius(13)
      .backgroundColor($r('app.color.surface'))

      Column({ space: 2 }) {
        Text(this.lastBackupAt > 0 ? '上次备份 '.concat(this.timeText()) : '还没有备份')
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
        Text(this.lastName.length > 0 ? this.lastName : '备份保存在你选择的位置')
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.actionLabel)
        .fontSize(AppFont.caption)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.brand_ink'))
        .padding({ left: 9, right: 9, top: 5, bottom: 5 })
        .borderRadius(Radius.pill)
        .backgroundColor($r('app.color.surface'))
        .onClick(() => {
          this.onTap();
        })
    }
    .width('100%')
    .padding(13)
    .borderRadius(Radius.card)
    .backgroundColor($r('app.color.brand_wash'))
    .border({ width: 1, color: $r('app.color.line') })
  }
}

class CsvTime {
  static pad(value: number): string {
    return value.toString().padStart(2, '0');
  }
}
