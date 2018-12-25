source("./data_updater.R")
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
  # geom_text(aes(label = n)) +
  labs(x = "Day", y = "Number of chests per day", title = "Number of chests opened per day") + 
  scale_x_date(date_breaks = "week") + 
  theme_minimal()

ggsave(filename = "daily_chests.jpg", path =  "./images_report")


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

ggsave(filename = "currency_rewards.jpg", path = "./images_report")

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

ggsave(filename = "hero_rewards.jpg", path = "./images_report")


########## CHANCES ANALYSIS ##########
OUTPUT <- list()
rarities <- c("Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical")
items_colours <- items[,c("Red", "Green", "Blue")]

### K-MEANS ON RAW DATA
set.seed(1234)
OUTPUT[[1]] <- kmeans(items_colours, 5)

### K-MEANS ON PCA OF RAW DATA
items_pca <- prcomp(items_colours)
ggbiplot(items_pca)

set.seed(1234)
OUTPUT[[2]] <- kmeans(items_pca$x[,1:2], 5)

## KNOWN CLASSIFICATION
# known data

known_centers <- items %>% filter(Day == "20181023" & Chest == "184920" & Hero == "BOOMER") %>% select(-Day, -Chest,-Hero) %>%
    bind_rows(
      items %>% filter(Day == "20181023" & Chest == "232704" & Hero == "HILT")%>% select(-Day, -Chest,-Hero)) %>%
    bind_rows(
      items %>% filter(Day == "20181024" & Chest == "214527" & Hero == "HILT")%>% select(-Day, -Chest,-Hero)) %>%
    bind_rows(
      items %>% filter(Day == "20181030" & Chest == "201039" & Hero == "BELLYLARF")%>% select(-Day, -Chest,-Hero)) %>%
    bind_rows(
      items %>% filter(Day == "20181115" & Chest == "151512" & Hero == "V")%>% select(-Day, -Chest,-Hero))

OUTPUT[[3]] <- kmeans(items_colours, centers = known_centers)

### OUTPUT COMPARISON

names(OUTPUT) <- c("KMEANS", "PCA-KMEANS", "GIVEN-CENTERS-KMEAN")

sapply(OUTPUT, function(x) x$betweenss/x$totss)

items_classification <- bind_rows(lapply(OUTPUT, function(x){
  aux <- fct_infreq(factor(x$cluster))
  out <- factor(aux, labels = rarities[1:length(levels(aux))])
  return(out)})) 

chances_plot <- bind_rows(apply(items_classification, 2, fct_count), .id = "Method") %>%
  group_by(Method) %>%
  mutate(chance = n/sum(n),
         Rarity = factor(f, levels = rarities))

ggplot(chances_plot, aes(x = Rarity, y = chance, fill = Method)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "", y = "Chance to get this item", title = "Chances to get an object of a given rarity in a Free Chest")

ggsave(filename = "chances_comparison.jpg", path = "./images_report")


chances_plot %>% select(-n, -f) %>%
  mutate(chance = chance*100) %>%
  spread(Rarity, chance)


