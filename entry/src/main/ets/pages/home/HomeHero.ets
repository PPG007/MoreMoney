import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { Book } from '../../models/Entities';
import { BookChip } from '../../components/base/BookChip';
import { EyeButton } from '../../components/base/EyeButton';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct HomeHero {
  @Param monthLabel: string = '';
  @Param books: Book[] = [];
  @Param selectedBookId: string = '';
  @Param lockedBookIds: string[] = [];
  @Event onSelectBook: (bookId: string) => void = (bookId: string) => {
  };
  @Event onSearch: () => void = () => {
  };
  @Event onPrevMonth: () => void = () => {
  };
  @Event onNextMonth: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private isLocked(bookId: string): boolean {
    return this.lockedBookIds.indexOf(bookId) >= 0;
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

      Row({ space: Space.x5 }) {
        this.heroIconButton($r('app.media.ic_chevron_left'), () => {
          this.onPrevMonth();
        })
        Text(this.monthLabel)
          .fontSize(AppFont.month)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.on_hero'))
          .fontFeature(AppFont.tnum)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        this.heroIconButton($r('app.media.ic_chevron_right'), () => {
          this.onNextMonth();
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
