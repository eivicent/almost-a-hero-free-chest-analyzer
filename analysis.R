rm(list = ls())
library(ggbiplot)
library(plotly)
library(tidyverse)
library(magrittr)
library(ggplot2)

basic <- read.table("./data/basic.txt", sep = ";", dec = ".", header = T, stringsAsFactors = F)
items <- read.table("./data/items.txt", sep = ";", dec = ".", header = T, stringsAsFactors = F)

basic %<>% separate(Code, c("Day", "Chest"),  sep = "-")
items %<>% separate(Code, c("Day", "Chest"),  sep = "-")

########## EXPLORATORY ANALYSIS ##########

basic %>% 
  summarise(chests = n_distinct(Chest),
            days = n_distinct(Day))

daily_chests_plot <- basic %>% group_by(Day) %>% summarise(n = n_distinct(Chest)) %>%
  mutate(Day = as.Date(Day, format = "%Y%m%d"))

ggplot(daily_chests_plot, aes(x = Day, y = n)) +
  geom_line(colour = "#00BFC4") +
  geom_text(aes(label = n)) +
  labs(x = "Day", y = "Number of chests per day", title = "Number of chests opened per day") + 
  scale_x_date(date_breaks = "week") + 
  theme_minimal()


currencies_plot <- basic %>% 
  count(Value, Item) %>%
  group_by(Item) %>%
  mutate(prop = n/sum(n))

currencies_expected_data <- data.frame("Item" = c("Scraps", "Tokens"),
                                       "Exp" = c(0.025, 0.1))


ggplot(currencies_plot, aes(x = Value , y = prop, fill = Item)) +
  geom_bar(stat = "identity") + 
  facet_grid(.~Item, scales = "free") +
  scale_y_continuous(labels = scales::percent,breaks = seq(0,1,by =0.025)) +
  scale_x_continuous(breaks = c(seq(5,15, by = 1), seq(20,60, by = 5))) +
  geom_hline(aes(yintercept = Exp, colour = Item), data = currencies_expected_data) + 
  labs(title = "% of rewards in chest chest",
       x = "Amount of currency per chest",
       y = "% of chance to get")

basic %>% group_by(Item) %>% summarise(max_value_obtained = max(Value))

items_plot <- items %>% count(Hero) %>%
  mutate(prop = n/sum(n))

expected_data <- data.frame("Hero" = unique(items_plot$Hero),
                            "Exp" = 1/15) 

ggplot(items_plot %>% arrange(Hero), aes(x = Hero , y= prop)) +
  geom_bar(stat = "identity", fill = "#00BFC4") +
  geom_hline(aes(yintercept = Exp), colour = "#00BFC4", data = expected_data) + 
  scale_y_continuous(labels = scales::percent) +
  coord_flip()


########## CHANCES ANALYSIS ##########



OUTPUT <- list()

### K-MEANS ON RAW DATA
rarities <- c("Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical")
potential_rarities <- 4:6

items_colours <- items[,c("Red", "Green", "Blue")]

set.seed(1234)
out <- c(); kk <- 1
aux <- list()
for(ii in potential_rarities){
  aux[[kk]] <- kmeans(items_colours, ii)
  out[kk] <- aux[[kk]]$betweenss/aux[[kk]]$totss
  kk <- kk + 1
}

OUTPUT[[1]] <- aux[[which.max(out)]]

### K-MEANS ON PCA OF RAW DATA
items_pca <- prcomp(items_colours)

summary(items_pca)
ggbiplot(items_pca)

set.seed(1234)
out <- c(); kk <- 1
aux <- list()
for(ii in potential_rarities){
  aux[[kk]] <- kmeans(items_pca$x[,1:2], ii)
  out[kk] <- aux[[kk]]$betweenss/aux[[kk]]$totss
  kk <- kk + 1
}

OUTPUT[[2]] <- aux[[which.max(out)]]

## SUPERVISED LEARNING
# known data

known_centers <- 




