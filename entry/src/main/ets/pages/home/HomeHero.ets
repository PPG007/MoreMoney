import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { Book } from '../../models/Entities';
import { BookChip } from '../../components/base/BookChip';
import { EyeButton } from '../../components/base/EyeButton';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct HomeHero {
  @Param periodLabel: string = '';
  @Param periodIndex: number = 1;
  @Param books: Book[] = [];
  @Param selectedBookId: string = '';
  @Param lockedBookIds: string[] = [];
  @Event onSelectBook: (bookId: string) => void = (bookId: string) => {
  };
  @Event onSearch: () => void = () => {
  };
  @Event onSelectPeriod: (index: number) => void = (index: number) => {
  };
  @Event onPrevPeriod: () => void = () => {
  };
  @Event onNextPeriod: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private isLocked(bookId: string): boolean {
    return this.lockedBookIds.indexOf(bookId) >= 0;
  }

  private static periodOptions(): string[] {
    return ['周', '月', '年'];
  }

  @Builder
  heroIconButton(icon: Resource, onTap: () => void) {
    Stack() {
      Image(icon)
        .width(17)
        .height(17)
        .fillColor($r('app.color.on_hero'))
    }
    .width(36)
    .height(36)
    .borderRadius(Radius.pill)
    .backgroundColor($r('app.color.hero_glass'))
    .border({ width: 1, color: $r('app.color.hero_line') })
    .responseRegion({ x: -4, y: -4, width: 44, height: 44 })
    .onClick(() => {
      onTap();
    })
  }

  build() {
    Column({ space: Space.x4 }) {
      Row() {
        Text('记账本')
          .fontSize(AppFont.pageTitle)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.on_hero'))
          .layoutWeight(1)
        Row({ space: Space.x2 }) {
          this.heroIconButton($r('app.media.ic_search'), () => {
            this.onSearch();
          })
          EyeButton({ hero: true })
        }
      }
      .width('100%')

      Row({ space: 6 }) {
        ForEach(HomeHero.periodOptions(), (label: string, index: number) => {
          Text(label)
            .fontSize(AppFont.caption)
            .fontWeight(this.periodIndex === index ? AppFont.semibold : AppFont.regular)
            .fontColor($r('app.color.on_hero'))
            .opacity(this.periodIndex === index ? 1 : 0.68)
            .padding({ left: 13, right: 13, top: 5, bottom: 5 })
            .borderRadius(Radius.pill)
            .backgroundColor(this.periodIndex === index ? $r('app.color.hero_glass') : Color.Transparent)
            .border({
              width: 1,
              color: this.periodIndex === index ? $r('app.color.hero_line') : Color.Transparent
            })
            .onClick(() => {
              this.onSelectPeriod(index);
            })
        }, (label: string) => label)
      }
      .width('100%')

      Row({ space: Space.x5 }) {
        this.heroIconButton($r('app.media.ic_chevron_left'), () => {
          this.onPrevPeriod();
        })
        Text(this.periodLabel)
          .fontSize(this.periodIndex === 0 ? 20 : AppFont.month)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.on_hero'))
          .fontFeature(AppFont.tnum)
          .maxLines(1)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        this.heroIconButton($r('app.media.ic_chevron_right'), () => {
          this.onNextPeriod();
        })
      }
      .width('100%')

      Scroll() {
        Row({ space: 6 }) {
          BookChip({
            label: '全部',
            isSelected: this.selectedBookId === '',
            onHero: true,
            onTap: () => {
              this.onSelectBook('');
            }
          })
          ForEach(this.books, (book: Book) => {
            BookChip({
              book: book,
              label: book.name,
              isSelected: this.selectedBookId === book.id,
              isLocked: this.isLocked(book.id),
              onHero: true,
              onTap: () => {
                this.onSelectBook(book.id);
              }
            })
          }, (book: Book) => book.id)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding({
      left: Space.x7,
      right: Space.x7,
      top: this.ui.topInset + 10,
      bottom: 78
    })
    .alignItems(HorizontalAlign.Start)
    .borderRadius({ bottomLeft: Radius.hero, bottomRight: Radius.hero })
    .linearGradient({
      angle: 152,
      colors: [
        [$r('app.color.hero_a'), 0],
        [$r('app.color.hero_b'), 0.52],
        [$r('app.color.hero_c'), 1]
      ]
    })
    .clip(true)
  }
}
