package com.github.ppg007.moremoney.ui.categories

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.appContainer
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.components.CategoryIconNames
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.components.base.AppTextField
import com.github.ppg007.moremoney.ui.components.base.Badge
import com.github.ppg007.moremoney.ui.components.base.ConfirmDialog
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.components.base.PrimaryButton
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.components.base.dashedBorder
import com.github.ppg007.moremoney.ui.components.iconResOf
import com.github.ppg007.moremoney.ui.components.layout.PageHeader
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.ui.theme.withAlpha
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.ErrorUtil
import com.github.ppg007.moremoney.util.IdUtil
import com.github.ppg007.moremoney.util.PinyinUtil
import kotlinx.coroutines.launch

/**
 * 分类管理：分组与分类 CRUD、图标/颜色、常用分类与拼音排序。
 *
 * 常用口径：近 30 天使用次数降序，次数相同按拼音、排序字段；最多 8 个。
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CategoryManageScreen(onBack: () -> Unit) {
  val container = LocalContext.current.appContainer
  val scope = rememberCoroutineScope()
  val colors = MoreMoneyTheme.colors
  val groups by container.categoryRepository.observeGroups().collectAsStateWithLifecycle(emptyList())
  val categories by container.categoryRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val txns by container.txnRepository.observeActive().collectAsStateWithLifecycle(emptyList())

  var editingCategory by remember { mutableStateOf<CategoryEntity?>(null) }
  var creatingCategoryIn by remember { mutableStateOf<String?>(null) }
  var actionCategory by remember { mutableStateOf<CategoryEntity?>(null) }
  var deletingCategory by remember { mutableStateOf<CategoryEntity?>(null) }
  var editingGroup by remember { mutableStateOf<CategoryGroupEntity?>(null) }
  var creatingGroup by remember { mutableStateOf(false) }

  val since = System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000
  val usage =
    txns.filter { it.occurredAt >= since }
      .groupingBy { it.categoryId }
      .eachCount()
  val frequent =
    categories
      .filter { !it.archived && usage.containsKey(it.id) }
      .sortedWith(compareByDescending<CategoryEntity> { usage[it.id] ?: 0 }.thenBy { it.pinyin }.thenBy { it.sort })
      .take(8)

  SystemBarAppearance()

  Column(modifier = Modifier.fillMaxSize().background(colors.background).navigationBarsPadding()) {
    PageHeader(title = "分类管理", onBack = onBack, trailing = { EyeButton(ui = container.ui) })

    Column(
      modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = Spacing.page),
      verticalArrangement = Arrangement.spacedBy(Spacing.x3),
    ) {
      Column(
        modifier =
          Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.card))
            .background(colors.surface)
            .border(1.dp, colors.line, RoundedCornerShape(Radius.card))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(Spacing.x3),
      ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
          Text(text = "常用", style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold), color = colors.ink)
          Badge("近 30 天")
          Spacer(Modifier.weight(1f))
          Text(text = "${frequent.size}/8", style = MoreMoneyTextStyles.caption, color = colors.ink3)
        }
        if (frequent.isEmpty()) {
          Text(
            text = "近 30 天还没有使用记录；记账后这里会按使用频率更新。",
            style = MoreMoneyTextStyles.caption,
            color = colors.ink3,
          )
        } else {
          FlowRow(
            horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
            verticalArrangement = Arrangement.spacedBy(Spacing.x2),
          ) {
            frequent.forEach { category ->
              CategoryChip(category = category, onClick = { actionCategory = category })
            }
          }
        }
      }

      groups.forEach { group ->
        val list = categories.filter { it.groupId == group.id }
        Column(
          modifier =
            Modifier
              .fillMaxWidth()
              .clip(RoundedCornerShape(Radius.cardSm))
              .background(colors.surface)
              .border(1.dp, colors.line, RoundedCornerShape(Radius.cardSm))
              .padding(13.dp),
          verticalArrangement = Arrangement.spacedBy(Spacing.x3),
        ) {
          Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
              text = group.name,
              style = MoreMoneyTextStyles.settingsTitle.copy(fontWeight = FontWeight.Bold),
              color = colors.ink,
              modifier = Modifier.weight(1f),
            )
            Text(text = "${list.size}", style = MoreMoneyTextStyles.caption, color = colors.ink3)
            if (!group.isSystem) {
              Text(
                text = "编辑",
                style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
                color = colors.brandInk,
                modifier = Modifier.padding(start = 10.dp).clickable { editingGroup = group },
              )
            }
          }
          FlowRow(
            horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
            verticalArrangement = Arrangement.spacedBy(Spacing.x2),
          ) {
            list.forEach { category ->
              CategoryChip(category = category, onClick = { actionCategory = category })
            }
            Text(
              text = "＋ 新建",
              style = MoreMoneyTextStyles.caption,
              color = colors.ink3,
              modifier =
                Modifier
                  .clip(RoundedCornerShape(Radius.pill))
                  .dashedBorder(colors.line, Radius.pill)
                  .clickable { creatingCategoryIn = group.id }
                  .padding(horizontal = 10.dp, vertical = 5.dp),
            )
          }
        }
      }

      PrimaryButton(
        text = "新建分组",
        onClick = { creatingGroup = true },
        leadingIcon = R.drawable.ic_plus,
        modifier = Modifier.padding(top = Spacing.x2),
      )
      Text(
        text = "分组可自定义；系统分组不可删除。分类被流水引用时只能归档，归档后不参与新增选择。",
        style = MoreMoneyTextStyles.caption,
        color = colors.ink3,
        modifier = Modifier.padding(top = Spacing.x2),
      )
      Spacer(Modifier.height(120.dp))
    }
  }

  val categoryInitial = editingCategory ?: creatingCategoryIn?.let { groupId ->
    CategoryEntity(
      id = "",
      groupId = groupId,
      name = "",
      icon = "ic_cat_other",
      color = SeedColors.neutral,
      pinyin = "",
      sort = categories.count { it.groupId == groupId },
      archived = false,
      createdAt = System.currentTimeMillis(),
    )
  }
  if (categoryInitial != null) {
    CategoryEditSheet(
      initial = categoryInitial,
      isNew = editingCategory == null,
      groups = groups,
      onDismiss = {
        editingCategory = null
        creatingCategoryIn = null
      },
      onSave = { name, groupId, icon, color ->
        scope.launch {
          try {
            val now = System.currentTimeMillis()
            val entity =
              if (categoryInitial.id.isEmpty()) {
                CategoryEntity(
                  id = "cat_${IdUtil.next()}",
                  groupId = groupId,
                  name = name,
                  icon = icon,
                  color = color,
                  pinyin = PinyinUtil.key(name),
                  sort = categories.count { it.groupId == groupId },
                  archived = false,
                  createdAt = now,
                )
              } else {
                categoryInitial.copy(
                  groupId = groupId,
                  name = name,
                  icon = icon,
                  color = color,
                  pinyin = PinyinUtil.key(name),
                )
              }
            container.categoryRepository.save(entity)
            container.ui.showSnack(if (categoryInitial.id.isEmpty()) "分类已创建" else "分类已更新")
            editingCategory = null
            creatingCategoryIn = null
          } catch (error: Exception) {
            container.ui.showSnack("保存失败：${ErrorUtil.messageOf(error)}")
          }
        }
      },
    )
  }

  actionCategory?.let { category ->
    AppBottomSheet(onDismiss = { actionCategory = null }) {
      SheetTitle(title = category.name, subtitle = "拼音 ${category.pinyin.ifEmpty { PinyinUtil.key(category.name) }}")
      ActionRow("编辑分类") {
        actionCategory = null
        editingCategory = category
      }
      if (category.archived) {
        ActionRow("取消归档") {
          scope.launch {
            runCatching { container.categoryRepository.unarchive(category.id) }
            container.ui.showSnack("分类已恢复")
            actionCategory = null
          }
        }
      } else {
        ActionRow("归档分类") {
          scope.launch {
            runCatching { container.categoryRepository.archive(category.id) }
            container.ui.showSnack("分类已归档")
            actionCategory = null
          }
        }
      }
      ActionRow("删除分类", danger = true) {
        actionCategory = null
        deletingCategory = category
      }
    }
  }

  val pendingDelete = deletingCategory
  ConfirmDialog(
    visible = pendingDelete != null,
    title = "删除分类「${pendingDelete?.name.orEmpty()}」？",
    message = "被流水引用的分类不能删除，请使用归档。",
    confirmLabel = "删除",
    danger = true,
    onConfirm = {
      if (pendingDelete != null) {
        scope.launch {
          try {
            container.categoryRepository.delete(pendingDelete)
            container.ui.showSnack("分类已删除")
          } catch (error: Exception) {
            container.ui.showSnack(ErrorUtil.messageOf(error))
          }
          deletingCategory = null
        }
      }
    },
    onDismiss = { deletingCategory = null },
  )

  if (creatingGroup || editingGroup != null) {
    GroupEditSheet(
      existing = editingGroup,
      hasChildren = editingGroup?.let { group -> categories.any { it.groupId == group.id } } ?: false,
      onDismiss = {
        creatingGroup = false
        editingGroup = null
      },
      onSave = { name ->
        scope.launch {
          try {
            val current = editingGroup
            if (current == null) {
              container.categoryRepository.insertGroup(
                CategoryGroupEntity(
                  id = "group_${IdUtil.next()}",
                  name = name,
                  sort = groups.size,
                  isSystem = false,
                )
              )
              container.ui.showSnack("分组已创建")
            } else {
              container.categoryRepository.renameGroup(current.id, name)
              container.ui.showSnack("分组已重命名")
            }
            creatingGroup = false
            editingGroup = null
          } catch (error: Exception) {
            container.ui.showSnack("保存失败：${ErrorUtil.messageOf(error)}")
          }
        }
      },
      onDelete = {
        val current = editingGroup ?: return@GroupEditSheet
        scope.launch {
          try {
            container.categoryRepository.deleteGroup(current.id)
            container.ui.showSnack("分组已删除")
          } catch (error: Exception) {
            container.ui.showSnack(ErrorUtil.messageOf(error))
          }
          editingGroup = null
        }
      },
    )
  }
}

@Composable
private fun GroupEditSheet(
  existing: CategoryGroupEntity?,
  hasChildren: Boolean,
  onDismiss: () -> Unit,
  onSave: (String) -> Unit,
  onDelete: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  var name by remember(existing) { mutableStateOf(existing?.name.orEmpty()) }
  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = if (existing == null) "新建分组" else "编辑分组")
    AppTextField(
      value = name,
      onValueChange = { name = it.take(12) },
      placeholder = "分组名称",
      height = 44,
    )
    PrimaryButton(text = "保存", enabled = name.trim().isNotEmpty(), onClick = { onSave(name.trim()) })
    if (existing != null) {
      Text(
        text = if (hasChildren) "分组下还有分类，无法删除" else "删除分组",
        style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
        color = if (hasChildren) colors.ink3 else colors.expense,
        modifier =
          Modifier
            .fillMaxWidth()
            .clickable(enabled = !hasChildren, onClick = onDelete)
            .padding(vertical = 8.dp),
      )
    }
  }
}

@Composable
private fun CategoryChip(
  category: CategoryEntity,
  onClick: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val color = parseColorOf(category.color)
  Row(
    modifier =
      Modifier
        .clip(RoundedCornerShape(Radius.pill))
        .background(if (category.archived) colors.surface2 else colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.pill))
        .clickable(onClick = onClick)
        .padding(horizontal = 8.dp, vertical = 4.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(5.dp),
  ) {
    Box(
      modifier =
        Modifier
          .size(21.dp)
          .clip(RoundedCornerShape(7.dp))
          .background(withAlpha(color, 0.13f)),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(iconResOf(category.icon)),
        contentDescription = null,
        tint = color,
        modifier = Modifier.size(13.dp),
      )
    }
    Text(
      text = category.name,
      style = MoreMoneyTextStyles.caption,
      color = if (category.archived) colors.ink3 else colors.ink,
    )
    if (category.archived) {
      Text(text = "已归档", style = MoreMoneyTextStyles.caption, color = colors.ink3)
    }
  }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun CategoryEditSheet(
  initial: CategoryEntity,
  isNew: Boolean,
  groups: List<CategoryGroupEntity>,
  onDismiss: () -> Unit,
  onSave: (name: String, groupId: String, icon: String, color: String) -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  var name by remember(initial) { mutableStateOf(initial.name) }
  var groupId by remember(initial) { mutableStateOf(initial.groupId) }
  var icon by remember(initial) { mutableStateOf(initial.icon) }
  var color by remember(initial) { mutableStateOf(initial.color) }

  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = if (isNew) "新建分类" else "编辑分类")
    AppTextField(value = name, onValueChange = { name = it.take(12) }, placeholder = "分类名称", height = 44)
    Text(text = "分组", style = MoreMoneyTextStyles.legend, color = colors.ink3)
    FlowRow(horizontalArrangement = Arrangement.spacedBy(Spacing.x2), verticalArrangement = Arrangement.spacedBy(Spacing.x2)) {
      groups.forEach { group ->
        val selected = groupId == group.id
        Text(
          text = group.name,
          style = MoreMoneyTextStyles.caption.copy(fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal),
          color = if (selected) colors.brandInk else colors.ink2,
          modifier =
            Modifier
              .clip(RoundedCornerShape(Radius.pill))
              .background(if (selected) colors.brandWash else colors.surface2)
              .border(1.dp, if (selected) colors.brandSoft else colors.line, RoundedCornerShape(Radius.pill))
              .clickable { groupId = group.id }
              .padding(horizontal = 10.dp, vertical = 5.dp),
        )
      }
    }
    Text(text = "图标", style = MoreMoneyTextStyles.legend, color = colors.ink3)
    FlowRow(horizontalArrangement = Arrangement.spacedBy(Spacing.x2), verticalArrangement = Arrangement.spacedBy(Spacing.x2)) {
      CategoryIconNames.forEach { item ->
        val selected = icon == item
        Box(
          modifier =
            Modifier
              .size(42.dp)
              .clip(RoundedCornerShape(12.dp))
              .background(if (selected) colors.brandWash else colors.surface2)
              .border(1.dp, if (selected) colors.brandInk else colors.line, RoundedCornerShape(12.dp))
              .clickable { icon = item },
          contentAlignment = Alignment.Center,
        ) {
          Icon(
            painter = painterResource(iconResOf(item)),
            contentDescription = null,
            tint = if (selected) colors.brandInk else colors.ink2,
            modifier = Modifier.size(21.dp),
          )
        }
      }
    }
    Text(text = "颜色", style = MoreMoneyTextStyles.legend, color = colors.ink3)
    FlowRow(horizontalArrangement = Arrangement.spacedBy(Spacing.x3), verticalArrangement = Arrangement.spacedBy(Spacing.x3)) {
      SeedColors.all.forEach { item ->
        val selected = color == item
        Box(
          modifier =
            Modifier
              .size(28.dp)
              .clip(RoundedCornerShape(10.dp))
              .background(parseColorOf(item))
              .clickable { color = item },
          contentAlignment = Alignment.Center,
        ) {
          if (selected) {
            Icon(
              painter = painterResource(R.drawable.ic_check),
              contentDescription = null,
              tint = colors.buttonForeground,
              modifier = Modifier.size(14.dp),
            )
          }
        }
      }
    }
    PrimaryButton(
      text = "保存",
      enabled = name.trim().isNotEmpty(),
      onClick = { onSave(name.trim(), groupId, icon, color) },
    )
  }
}

@Composable
private fun ActionRow(
  text: String,
  danger: Boolean = false,
  onClick: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      Modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.chip))
        .background(colors.surface2)
        .clickable(onClick = onClick)
        .padding(vertical = 12.dp),
    horizontalArrangement = Arrangement.Center,
  ) {
    Text(
      text = text,
      style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.SemiBold),
      color = if (danger) colors.expense else colors.ink,
    )
  }
}
