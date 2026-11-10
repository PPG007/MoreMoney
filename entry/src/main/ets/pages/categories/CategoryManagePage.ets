import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { Category, CategoryGroup } from '../../models/Entities';
import { NavResult } from '../../models/NavParams';
import { CategoryDao } from '../../data/db/CategoryDao';
import { CategoryService } from '../../service/CategoryService';
import { pinyinKey } from '../../utils/PinyinUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { SeedColors } from '../../theme/Palette';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { FrequentCard } from './FrequentCard';
import { GroupCard, CategoryGroupView } from './GroupCard';
import { CategoryEditSheet, CategoryDraft } from './CategoryEditSheet';
import { GroupEditSheet, GroupDraft } from './GroupEditSheet';

const FREQUENT_DAYS: number = 30;
const FREQUENT_LIMIT: number = 8;

@Builder
export function CategoryManageBuilder() {
  CategoryManagePage();
}

@ComponentV2
export struct CategoryManagePage {
  stack: NavPathStack = new NavPathStack();
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local groups: CategoryGroupView[] = [];
  @Local groupList: CategoryGroup[] = [];
  @Local frequent: Category[] = [];
  @Local editMode: boolean = false;
  @Local showCategoryEdit: boolean = false;
  @Local showGroupEdit: boolean = false;
  @Local editingCategory: Category | null = null;
  @Local editingGroup: CategoryGroup | null = null;
  @Local defaultGroupId: string = '';
  @Local errorText: string = '';

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.errorText = '';
      const groups: CategoryGroup[] = await CategoryDao.listGroups();
      this.groupList = groups;
      const views: CategoryGroupView[] = [];
      for (const group of groups) {
        const categories: Category[] = await CategoryDao.listByGroup(group.id);
        const view: CategoryGroupView = new CategoryGroupView();
        view.group = group;
        view.categories = categories.filter((category: Category): boolean => !category.archived);
        views.push(view);
      }
      this.groups = views;
      const since: number = Date.now() - FREQUENT_DAYS * 24 * 60 * 60 * 1000;
      this.frequent = await CategoryService.listFrequent(FREQUENT_LIMIT, since);
    } catch (error) {
      this.errorText = ErrorUtil.messageOf(error);
    }
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private maxSort(): number {
    let max: number = 0;
    for (const view of this.groups) {
      for (const category of view.categories) {
        if (category.sort > max) {
          max = category.sort;
        }
      }
    }
    return max;
  }

  private openCreateCategory(groupId: string): void {
    this.editingCategory = null;
    this.defaultGroupId = groupId;
    this.showCategoryEdit = true;
  }

  private openEditCategory(category: Category): void {
    this.editingCategory = category;
    this.defaultGroupId = category.groupId;
    this.showCategoryEdit = true;
  }

  private openCreateGroup(): void {
    this.editingGroup = null;
    this.showGroupEdit = true;
  }

  private openEditGroup(group: CategoryGroup): void {
    this.editingGroup = group;
    this.showGroupEdit = true;
  }

  private async saveCategory(draft: CategoryDraft): Promise<void> {
    try {
      if (draft.id.length === 0) {
        const category: Category = {
          id: 'cat_'.concat(Date.now().toString()).concat('_').concat(Math.floor(Math.random() * 1000).toString()),
          groupId: draft.groupId,
          name: draft.name,
          icon: draft.icon,
          color: draft.color,
          pinyin: pinyinKey(draft.name),
          sort: this.maxSort() + 1,
          archived: false,
          createdAt: Date.now()
        };
        await CategoryDao.insert(category);
      } else {
        const existing: Category | undefined = this.findCategory(draft.id);
        if (existing === undefined) {
          return;
        }
        const updated: Category = {
          id: existing.id,
          groupId: draft.groupId,
          name: draft.name,
          icon: draft.icon,
          color: draft.color,
          pinyin: pinyinKey(draft.name),
          sort: existing.sort,
          archived: existing.archived,
          createdAt: existing.createdAt
        };
        await CategoryDao.update(updated);
      }
      this.showCategoryEdit = false;
      this.editingCategory = null;
      await this.reload();
      SnackBarService.show(CategoryManagePage.toast('已保存'));
    } catch (error) {
      SnackBarService.show(CategoryManagePage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private findCategory(id: string): Category | undefined {
    for (const view of this.groups) {
      const found: Category | undefined = view.categories.find((category: Category): boolean => category.id === id);
      if (found !== undefined) {
        return found;
      }
    }
    return undefined;
  }

  private async deleteCategory(category: Category): Promise<void> {
    try {
      const refs: number = await CategoryService.countReferences(category.id);
      if (refs > 0) {
        await CategoryDao.archive(category.id);
        await this.reload();
        SnackBarService.show(CategoryManagePage.toast('该分类已有流水，已归档'));
        return;
      }
      AlertDialog.show({
        title: '删除分类',
        message: '确定删除「'.concat(category.name).concat('」吗？'),
        primaryButton: {
          value: '取消',
          action: () => {
          }
        },
        secondaryButton: {
          value: '删除',
          fontColor: $r('app.color.expense'),
          action: () => {
            this.performDeleteCategory(category);
          }
        }
      });
    } catch (error) {
      SnackBarService.show(CategoryManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async performDeleteCategory(category: Category): Promise<void> {
    try {
      await CategoryDao.delete(category.id);
      await this.reload();
      SnackBarService.show(CategoryManagePage.toast('已删除'));
    } catch (error) {
      SnackBarService.show(CategoryManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async deleteGroup(group: CategoryGroup): Promise<void> {
    if (group.isSystem) {
      SnackBarService.show(CategoryManagePage.toast('系统分组不可删除'));
      return;
    }
    try {
      await CategoryDao.deleteGroup(group.id);
      await this.reload();
      SnackBarService.show(CategoryManagePage.toast('已删除分组'));
    } catch (error) {
      SnackBarService.show(CategoryManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async saveGroup(draft: GroupDraft): Promise<void> {
    try {
      if (draft.id.length === 0) {
        const group: CategoryGroup = {
          id: 'group_'.concat(Date.now().toString()),
          name: draft.name,
          sort: this.groupList.length,
          isSystem: false
        };
        await CategoryDao.insertGroup(group);
      } else {
        await CategoryDao.renameGroup(draft.id, draft.name);
      }
      this.showGroupEdit = false;
      this.editingGroup = null;
      await this.reload();
      SnackBarService.show(CategoryManagePage.toast('已保存'));
    } catch (error) {
      SnackBarService.show(CategoryManagePage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
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
        this.stack.pop(new NavResult());
      })

      Text('分类管理')
        .fontSize(AppFont.subTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)

      Text(this.editMode ? '完成' : '编辑')
        .fontSize(AppFont.settings)
        .fontWeight(AppFont.semibold)
        .fontColor($r('app.color.brand_ink'))
        .padding({ left: 8, right: 2, top: 6, bottom: 6 })
        .onClick(() => {
          this.editMode = !this.editMode;
        })
    }
    .width('100%')
    .height(52 + this.ui.topInset)
    .padding({ top: this.ui.topInset, left: Space.page, right: Space.page })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.header()

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.expense'))
              .padding({ left: Space.page, right: Space.page })
          }

          Scroll() {
            Column({ space: Space.x3 }) {
              FrequentCard({
                categories: this.frequent,
                onEditCategory: (category: Category) => {
                  this.openEditCategory(category);
                }
              })

              ForEach(this.groups, (view: CategoryGroupView) => {
                GroupCard({
                  data: view,
                  editMode: this.editMode,
                  onEditGroup: (group: CategoryGroup) => {
                    this.openEditGroup(group);
                  },
                  onDeleteGroup: (group: CategoryGroup) => {
                    this.deleteGroup(group);
                  },
                  onEditCategory: (category: Category) => {
                    this.openEditCategory(category);
                  },
                  onDeleteCategory: (category: Category) => {
                    this.deleteCategory(category);
                  },
                  onAddCategory: (groupId: string) => {
                    this.openCreateCategory(groupId);
                  }
                })
              }, (view: CategoryGroupView) => view.group.id)

              Row({ space: 6 }) {
                Text('+')
                  .fontSize(AppFont.subTitle)
                  .fontWeight(AppFont.bold)
                  .fontColor($r('app.color.ink_3'))
                Text('新建分组')
                  .fontSize(AppFont.settings)
                  .fontWeight(AppFont.semibold)
                  .fontColor($r('app.color.ink_3'))
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.Center)
              .borderRadius(Radius.cardSm)
              .border({ width: 1, color: $r('app.color.line'), style: BorderStyle.Dashed })
              .onClick(() => {
                this.openCreateGroup();
              })

              Row().width('100%').height(40)
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page, top: Space.x3 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')

        CategoryEditSheet({
          visible: this.showCategoryEdit,
          isEdit: this.editingCategory !== null,
          initialId: this.editingCategory === null ? '' : this.editingCategory.id,
          initialName: this.editingCategory === null ? '' : this.editingCategory.name,
          initialGroupId: this.editingCategory === null ? this.defaultGroupId : this.editingCategory.groupId,
          initialIcon: this.editingCategory === null ? 'ic_cat_other' : this.editingCategory.icon,
          initialColor: this.editingCategory === null ? SeedColors.neutral : this.editingCategory.color,
          groups: this.groupList,
          onSave: (draft: CategoryDraft) => {
            this.saveCategory(draft);
          },
          onClose: () => {
            this.showCategoryEdit = false;
            this.editingCategory = null;
          }
        })

        GroupEditSheet({
          visible: this.showGroupEdit,
          isEdit: this.editingGroup !== null,
          initialId: this.editingGroup === null ? '' : this.editingGroup.id,
          initialName: this.editingGroup === null ? '' : this.editingGroup.name,
          onSave: (draft: GroupDraft) => {
            this.saveGroup(draft);
          },
          onClose: () => {
            this.showGroupEdit = false;
            this.editingGroup = null;
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
    .onReady((context: NavDestinationContext) => {
      this.stack = context.pathStack;
    })
  }
}
