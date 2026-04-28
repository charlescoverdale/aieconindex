# Figure generator for the aieconindex R Journal paper.
#
# Produces three figures from real Anthropic Economic Index data
# fetched via the package itself:
#
#   fig1.pdf : Augmentation vs automation by interaction type
#              (release_2025_03_27, automation_vs_augmentation_v2.csv)
#   fig2.pdf : Top-15 O*NET tasks in the United Kingdom by share of
#              Claude.ai usage (release_2025_09_15, GBR slice)
#   fig3.pdf : Cross-country usage per-capita index for selected
#              countries (release_2025_09_15, country facet)

suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(showtext)
})

font_add("HelveticaNeue",
         regular = "/System/Library/Fonts/Helvetica.ttc",
         bold = "/System/Library/Fonts/Helvetica.ttc",
         italic = "/System/Library/Fonts/Helvetica.ttc")
showtext_auto()
showtext_opts(dpi = 300)

fig_dir <- "paper/figures"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

ok_blue   <- "#0072B2"
ok_orange <- "#E69F00"
ok_green  <- "#009E73"
ok_red    <- "#D55E00"
ok_purple <- "#CC79A7"
ok_yellow <- "#F0E442"
ok_sky    <- "#56B4E9"

fam <- "HelveticaNeue"

theme_wp <- function(base_size = 10) {
  theme_bw(base_size = base_size, base_family = fam) +
    theme(
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      plot.caption = element_blank(),
      panel.border = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(linewidth = 0.25, colour = "grey85"),
      axis.line = element_line(linewidth = 0.35, colour = "grey25"),
      axis.ticks = element_line(linewidth = 0.35, colour = "grey25"),
      axis.ticks.length = unit(2.5, "pt"),
      axis.text = element_text(size = base_size, colour = "grey20"),
      axis.title = element_text(size = base_size, colour = "grey20"),
      legend.position = "bottom",
      legend.title = element_blank(),
      legend.text = element_text(size = base_size - 1, family = fam),
      legend.key.height = unit(10, "pt"),
      legend.key.width = unit(22, "pt"),
      legend.spacing.x = unit(10, "pt"),
      legend.margin = margin(4, 0, 0, 0),
      plot.margin = margin(6, 10, 6, 6)
    )
}

# Use a stable cache directory inside the paper build so that
# regeneration is deterministic.
options(aieconindex.cache_dir = file.path(getwd(), "paper", ".aei_cache"))

# -----------------------------------------------------------------------------
# Figure 1: Augmentation vs automation by interaction type
# -----------------------------------------------------------------------------

f1 <- aei_download("2025-03-27", "automation_vs_augmentation_v2.csv")
# Six interaction types collapse to two families per Handa et al. (2025):
# automation = directive + feedback loop; augmentation = task iteration +
# learning + validation. The "none" row reflects unclassifiable.
f1$family <- ifelse(
  f1$interaction_type %in% c("directive", "feedback loop"), "Automation",
  ifelse(f1$interaction_type %in% c("task iteration", "learning", "validation"),
         "Augmentation", "Other")
)
# Order interaction types for readability.
f1$interaction_type <- factor(
  f1$interaction_type,
  levels = c("directive", "feedback loop",
             "task iteration", "learning", "validation",
             "none")
)

p1 <- ggplot(f1, aes(x = interaction_type, y = pct, fill = family)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%.1f", pct)),
            family = fam, size = 3.0, vjust = -0.5, colour = "grey20") +
  scale_fill_manual(values = c("Automation" = ok_red,
                               "Augmentation" = ok_blue,
                               "Other" = "grey70")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = NULL, y = "Share of conversations (per cent)") +
  theme_wp(base_size = 10) +
  theme(axis.text.x = element_text(angle = 0))

ggsave(file.path(fig_dir, "fig1.pdf"),
       p1, width = 5.5, height = 3.2, device = cairo_pdf)

cat("fig1.pdf written\n")

# -----------------------------------------------------------------------------
# Figure 2: Top 15 O*NET tasks in the UK by share of Claude.ai usage
# -----------------------------------------------------------------------------

uk <- aei_geography("2025-09-15", country = "GBR")
uk_tasks <- uk[uk$facet == "onet_task" &
                 uk$variable == "onet_task_pct" &
                 !is.na(uk$value) &
                 !uk$cluster_name %in% c("not_classified", "none"), ]
uk_tasks <- uk_tasks[order(-uk_tasks$value), ][seq_len(min(15L, nrow(uk_tasks))), ]
# Trim long task labels to keep the chart readable.
trim_label <- function(x, n = 60) {
  ifelse(nchar(x) > n, paste0(substr(x, 1, n - 1), "..."), x)
}
uk_tasks$cluster_short <- trim_label(uk_tasks$cluster_name, 65)
uk_tasks$cluster_short <- factor(uk_tasks$cluster_short,
                                 levels = rev(uk_tasks$cluster_short))

p2 <- ggplot(uk_tasks, aes(x = value, y = cluster_short)) +
  geom_col(fill = ok_blue, width = 0.7) +
  geom_text(aes(label = sprintf("%.2f%%", value)),
            family = fam, size = 2.7, hjust = -0.15, colour = "grey20") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.18))) +
  labs(x = "Share of UK Claude.ai usage (per cent)", y = NULL) +
  theme_wp(base_size = 9) +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(linewidth = 0.25, colour = "grey85"))

ggsave(file.path(fig_dir, "fig2.pdf"),
       p2, width = 5.5, height = 3.4, device = cairo_pdf)

cat("fig2.pdf written\n")

# -----------------------------------------------------------------------------
# Figure 3: Cross-country usage per-capita index, selected economies
# -----------------------------------------------------------------------------

enriched <- aei_index("2025-09-15", source = "claude_ai", variant = "enriched")
country_idx <- enriched[enriched$geography == "country" &
                          enriched$variable == "usage_per_capita_index" &
                          enriched$cluster_name == "not_classified", ]
# `usage_per_capita_index` rows of the not_classified cluster carry the
# country-level overall figure (1.0 = proportional to working-age
# population share, >1 = over-representation). Pick a tractable set of
# OECD economies to plot.
sel <- c("ISR", "SGP", "AUS", "CAN", "GBR", "USA",
         "NZL", "IRL", "NLD", "DEU", "FRA",
         "ESP", "ITA", "JPN", "KOR")
country_idx <- country_idx[country_idx$geo_id %in% sel, ]
# Some countries appear with multiple `level` rows (overall vs sub-facets);
# the country-level overall is level == 0.
if ("level" %in% names(country_idx)) {
  country_idx <- country_idx[country_idx$level == 0, ]
}
country_idx <- country_idx[order(-country_idx$value), ]
country_idx$geo_id <- factor(country_idx$geo_id, levels = rev(country_idx$geo_id))

p3 <- ggplot(country_idx, aes(x = value, y = geo_id)) +
  geom_vline(xintercept = 1, linewidth = 0.4, colour = "grey60", linetype = "dashed") +
  geom_col(fill = ok_blue, width = 0.7) +
  geom_text(aes(label = sprintf("%.2f", value)),
            family = fam, size = 2.7, hjust = -0.2, colour = "grey20") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Usage per working-age capita, index (1 = proportional)",
       y = NULL) +
  theme_wp(base_size = 10) +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(linewidth = 0.25, colour = "grey85"))

ggsave(file.path(fig_dir, "fig3.pdf"),
       p3, width = 5.5, height = 3.0, device = cairo_pdf)

cat("fig3.pdf written\n")

cat("\n--- done ---\n")
