# Load libraries ---------------------------------------------------------------

library(tidyverse)
library(lubridate)
library(patchwork)

# Import data ------------------------------------------------------------------

# Download data
spotify_songs_raw <- 
  read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-01-21/spotify_songs.csv')

# Helper functions -------------------------------------------------------------

# Finds the most common element of vector
most_common <- function(vec){
  names(which.max(table(vec)))
}

# Tidy/transform ---------------------------------------------------------------

albums <- spotify_songs_raw %>%
  mutate(track_album_release_date = ymd(track_album_release_date),
         playlist_genre = str_to_upper(playlist_genre)) %>% 
  group_by(track_album_id, track_album_name, track_album_release_date) %>% 
  summarise(
    tracks = n_distinct(track_id),
    avg_rating = mean(track_popularity, na.rm = T),
    genre = most_common(playlist_genre)) %>% 
  ungroup()

# Visualise --------------------------------------------------------------------

# Big plot:
(p1 <- albums %>% 
  filter(tracks >= 3) %>% arrange(desc(tracks)) %>% 
  mutate(genre = genre %>% 
           fct_reorder(track_album_release_date) %>% 
           fct_rev()) %>% 
  ggplot(aes(x = track_album_release_date, y = avg_rating, size = tracks,
             color = genre, group = 1, label = track_album_name)) +
  geom_smooth(lty = 0, fill = "salmon") +
  geom_point(pch = 21, stroke = 1.1) +
  geom_text(alpha = 0.4, size = 3, check_overlap = TRUE, 
            family = "RobotoCondensed-Regular") +
  expand_limits(y = 100) +
  theme_minimal(base_family = "RobotoCondensed-Regular",
                base_size = 15) +
   labs(title = "Spotify album popularity across release dates", 
        subtitle = "If you're listening to a 70's album on Spotify, it's probably a rock album",
        x = NULL, y = "Avg track rating", size = "Tracks", color = "Genre") +
  scale_radius(range = c(2, 20)) +
  vapeplot::scale_color_vapeplot_d())

# Small facetted one:
(p2 <- p1 +
  facet_wrap(~ genre, nrow = 1) +
  theme(strip.text = element_text(hjust = 0)) +
  lims(y = c(0,100)) +
  labs(title = NULL, subtitle = NULL, x = "Album release date"))

# Patchwork! -------------------------------------------------------------------

layout <- "
AAAA
AAAA
AAAA
AAAA
AAAA
BBBB
"

(p1 / p2) +
  plot_layout(design = layout, guides = "collect")&
  guides(size  = guide_legend(order = 1, override.aes = list(fill = NA)),
         color = guide_legend(override.aes = list(fill = NA))) &
  theme(legend.position = "bottom",
        legend.box = "horizontal",
        legend.justification = 1,
        panel.background = element_rect(
          fill = "#F5F5F5",
          colour = "#F5F5F5",
          size = 0.5),
        plot.background = element_rect(
          fill = "#F5F5F5", 
          color = "#F5F5F5"))

ggsave("wk04_spotify/albums.png", width = 25, height = 35, unit = "cm", dpi = 600)
