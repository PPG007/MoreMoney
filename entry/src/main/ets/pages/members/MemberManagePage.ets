import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { memberColorOf } from '../../theme/Palette';
import { Member } from '../../models/Entities';
import { MemberDao } from '../../data/db/MemberDao';
import { TxnDao } from '../../data/db/TxnDao';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { MemberDot } from '../../components/base/MemberDot';
import { AppBadge, BadgeTone } from '../../components/base/Badge';
import { EmptyState } from '../../components/base/EmptyState';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';
import { MemberEditSheet, MemberDraft } from './MemberEditSheet';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@Builder
export function MemberManageBuilder() {
  MemberManagePage();
}

@ComponentV2
export struct MemberManagePage {
  stack: NavPathStack = new NavPathStack();
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local members: Member[] = [];
  @Local showArchived: boolean = false;
  @Local showEdit: boolean = false;
  @Local editing: Member | null = null;
  @Local actionMember: Member | null = null;
  @Local loading: boolean = true;

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.members = await MemberDao.list();
    } catch (error) {
      SnackBarService.show(MemberManagePage.toast(ErrorUtil.messageOf(error)));
    } finally {
      this.loading = false;
    }
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private visibleMembers(): Member[] {
    return this.members.filter((member: Member): boolean => this.showArchived || !member.archived);
  }

  private activeCount(): number {
    return this.members.filter((member: Member): boolean => !member.archived).length;
  }

  private colorOf(member: Member): string {
    return memberColorOf(member.color, this.ui.isDark);
  }

  private openCreate(): void {
    this.editing = null;
    this.showEdit = true;
  }

  private openEdit(member: Member): void {
    this.editing = member;
    this.showEdit = true;
    this.actionMember = null;
  }

  private requestAction(member: Member): void {
    this.actionMember = member;
  }

  private actionName(): string {
    return this.actionMember === null ? '' : this.actionMember.name;
  }

  private async saveDraft(draft: MemberDraft): Promise<void> {
    try {
      if (draft.id.length === 0) {
        const list: Member[] = await MemberDao.list();
        const member: Member = {
          id: 'member_'.concat(Date.now().toString()).concat('_').concat(Math.floor(Math.random() * 1000).toString()),
          name: draft.name,
          initial: draft.initial,
          color: draft.colorKey,
          isDefault: draft.isDefault,
          sort: list.length,
          archived: false
        };
        if (draft.isDefault || this.activeCount() === 0) {
          await MemberDao.insert(member);
          if (draft.isDefault) {
            await MemberDao.setDefault(member.id);
          }
        } else {
          await MemberDao.insert(member);
        }
      } else {
        const existing: Member | undefined = this.members.find((item: Member): boolean => item.id === draft.id);
        if (existing === undefined) {
          return;
        }
        const updated: Member = {
          id: existing.id,
          name: draft.name,
          initial: draft.initial,
          color: draft.colorKey,
          isDefault: existing.isDefault,
          sort: existing.sort,
          archived: existing.archived
        };
        await MemberDao.update(updated);
        if (draft.isDefault && !existing.isDefault) {
          await MemberDao.setDefault(existing.id);
        }
      }
      this.showEdit = false;
      this.editing = null;
      await this.reload();
      SnackBarService.show(MemberManagePage.toast('已保存'));
    } catch (error) {
      SnackBarService.show(MemberManagePage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private async setDefault(member: Member): Promise<void> {
    try {
      await MemberDao.setDefault(member.id);
      this.actionMember = null;
      await this.reload();
      SnackBarService.show(MemberManagePage.toast('已将「'.concat(member.name).concat('」设为默认')));
    } catch (error) {
      SnackBarService.show(MemberManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async archive(member: Member): Promise<void> {
    if (member.isDefault) {
      SnackBarService.show(MemberManagePage.toast('默认成员不可归档，请先指定新的默认成员'));
      return;
    }
    if (this.activeCount() <= 1) {
      SnackBarService.show(MemberManagePage.toast('至少保留一位成员'));
      return;
    }
    try {
      await MemberDao.archive(member.id);
      this.actionMember = null;
      await this.reload();
      SnackBarService.show(MemberManagePage.toast('已归档'));
    } catch (error) {
      SnackBarService.show(MemberManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async restore(member: Member): Promise<void> {
    try {
      await MemberDao.unarchive(member.id);
      this.actionMember = null;
      await this.reload();
      SnackBarService.show(MemberManagePage.toast('已恢复'));
    } catch (error) {
      SnackBarService.show(MemberManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async requestDelete(member: Member): Promise<void> {
    if (member.isDefault) {
      SnackBarService.show(MemberManagePage.toast('默认成员不可删除，请先指定新的默认成员'));
      return;
    }
    if (this.activeCount() <= 1) {
      SnackBarService.show(MemberManagePage.toast('至少保留一位成员'));
      return;
    }
    let txnCount: number = 0;
    try {
      txnCount = await TxnDao.countByMember(member.id);
    } catch (error) {
      SnackBarService.show(MemberManagePage.toast(ErrorUtil.messageOf(error)));
      return;
    }
    if (txnCount > 0) {
      SnackBarService.show(MemberManagePage.toast('该成员已有流水，请使用归档'));
      return;
    }
    this.actionMember = null;
    AlertDialog.show({
      title: '删除成员',
      message: '确定删除「'.concat(member.name).concat('」吗？'),
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('app.color.expense'),
        action: () => {
          this.performDelete(member);
        }
      }
    });
  }

  private async performDelete(member: Member): Promise<void> {
    try {
      await MemberDao.delete(member.id);
      await this.reload();
      SnackBarService.show(MemberManagePage.toast('已删除'));
    } catch (error) {
      SnackBarService.show(MemberManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  @Builder
  header() {
    Row({ space: Space.x2 }) {
      Stack() {
        Image($r('app.media.ic_back'))
          .width(IconSize.back)
          .height(IconSize.back)
          .fillColor($r('app.color.ink'))
      }
      .width(34)
      .height(34)
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
      .onClick(() => {
        this.stack.pop();
      })

      Text('成员管理')
        .fontSize(AppFont.subTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)

      Stack() {
        Image($r('app.media.ic_plus'))
          .width(17)
          .height(17)
          .fillColor($r('app.color.brand_ink'))
      }
      .width(34)
      .height(34)
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.brand_wash'))
      .onClick(() => {
        this.openCreate();
      })
    }
    .width('100%')
    .height(52 + this.ui.topInset)
    .padding({ top: this.ui.topInset, left: Space.page, right: Space.page })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  memberRow(member: Member, index: number) {
    Row({ space: 11 }) {
      MemberDot({
        initial: member.initial,
        color: this.colorOf(member),
        dotSize: 21
      })
      Text(member.name)
        .fontSize(AppFont.settings)
        .fontWeight(AppFont.medium)
        .fontColor($r('app.color.ink'))
        .maxLines(1)
        .layoutWeight(1)
      if (member.isDefault) {
        AppBadge({ text: '默认' })
      }
      if (member.archived) {
        AppBadge({ text: '已归档', tone: BadgeTone.Warn })
      }
      Stack() {
        Image($r('app.media.ic_more'))
          .width(17)
          .height(17)
          .fillColor($r('app.color.ink_3'))
      }
      .width(34)
      .height(34)
      .borderRadius(Radius.pill)
      .onClick(() => {
        this.requestAction(member);
      })
    }
    .width('100%')
    .height(52)
    .padding({ left: 13, right: 13 })
    .backgroundColor($r('app.color.surface'))
    .border({
      width: { bottom: index === this.visibleMembers().length - 1 ? 0 : 1 },
      color: $r('app.color.line')
    })
    .borderRadius({
      topLeft: index === 0 ? Radius.card : 0,
      topRight: index === 0 ? Radius.card : 0,
      bottomLeft: index === this.visibleMembers().length - 1 ? Radius.card : 0,
      bottomRight: index === this.visibleMembers().length - 1 ? Radius.card : 0
    })
  }

  @Builder
  actionRow(label: string, color: ResourceColor, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(AppFont.row)
        .fontWeight(AppFont.medium)
        .fontColor(color)
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  actionSheet() {
    if (this.actionMember !== null) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.actionMember = null;
          })
        Column() {
          Row() {
            Text(this.actionName())
              .fontSize(AppFont.body)
              .fontWeight(AppFont.bold)
              .fontColor($r('app.color.ink'))
              .layoutWeight(1)
            Text('取消')
              .fontSize(AppFont.settings)
              .fontColor($r('app.color.ink_3'))
              .onClick(() => {
                this.actionMember = null;
              })
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .border({ width: { bottom: 1 }, color: $r('app.color.line') })

          this.actionRow('编辑', $r('app.color.ink'), () => {
            if (this.actionMember !== null) {
              this.openEdit(this.actionMember);
            }
          })
          if (this.actionMember !== null && !this.actionMember.isDefault && !this.actionMember.archived) {
            this.actionRow('设为默认', $r('app.color.ink'), () => {
              if (this.actionMember !== null) {
                this.setDefault(this.actionMember);
              }
            })
          }
          if (this.actionMember !== null && !this.actionMember.archived) {
            this.actionRow('归档', $r('app.color.ink'), () => {
              if (this.actionMember !== null) {
                this.archive(this.actionMember);
              }
            })
          }
          if (this.actionMember !== null && this.actionMember.archived) {
            this.actionRow('恢复', $r('app.color.brand_ink'), () => {
              if (this.actionMember !== null) {
                this.restore(this.actionMember);
              }
            })
          }
          this.actionRow('删除', $r('app.color.expense'), () => {
            if (this.actionMember !== null) {
              this.requestDelete(this.actionMember);
            }
          })
        }
        .width('100%')
        .padding({ bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
      }
      .width('100%')
      .height('100%')
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.header()

          if (this.visibleMembers().length === 0) {
            Column() {
              EmptyState({
                icon: $r('app.media.ic_member'),
                title: '还没有成员',
                description: '至少保留一位成员'
              })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.visibleMembers(), (member: Member, index: number) => {
                ListItem() {
                  this.memberRow(member, index)
                }
              }, (member: Member) => member.id)

              ListItem() {
                Row() {
                  Text(this.showArchived ? '隐藏已归档' : '显示已归档')
                    .fontSize(AppFont.caption)
                    .fontWeight(AppFont.semibold)
                    .fontColor($r('app.color.brand_ink'))
                }
                .width('100%')
                .height(44)
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  this.showArchived = !this.showArchived;
                })
              }
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: Space.page, right: Space.page, top: Space.x2 })
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')

        this.actionSheet()
      }
      .width('100%')
      .height('100%')

      MemberEditSheet({
        visible: this.showEdit,
        isEdit: this.editing !== null,
        initialId: this.editing === null ? '' : this.editing.id,
        initialName: this.editing === null ? '' : this.editing.name,
        initialColorKey: this.editing === null ? 'self' : this.editing.color,
        initialDefault: this.editing === null ? false : this.editing.isDefault,
        onSave: (draft: MemberDraft) => {
          this.saveDraft(draft);
        },
        onClose: () => {
          this.showEdit = false;
          this.editing = null;
        }
      })
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
    .onReady((context: NavDestinationContext) => {
      this.stack = context.pathStack;
    })
  }
}
