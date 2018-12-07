rm(list =ls())
library(ggbiplot)
library(tidyverse)
library(imager)
library(tesseract)

# library(magick)

##########  NOTATION #################
## TOKENS
# x > 820 & x < 870, y > 855 & y < 885
## SCARPS 
# x > 820 & x < 870, y > 960 & y < 995

## OBJECT 1
# Object ALL
# x > 170 & x < 285, y > 1070 & y < 1190
# Object 1 pixel
# x == 230, y == 1180
# Hero
# x > 310 & x < 650, y > 1095 & y < 1125

## OBJECT 2
# Object ALL
# x > 170 & x < 285, y > 1215 & y <  1330
# Object 1 pixel
# x == 230, y == 1325
# Hero
# x > 310 & x < 650, y > 1240 & y < 1270

##########  FUNCTIONS  #################

get_tokens <- function(im_name, directory){
  
  input_path <- paste0(directory, im_name)
  output_path <- paste0(directory, "aux_tokens.jpg")
  
  im <- load.image(input_path)
  if(width(im) == 1080 & height(im) == 2220){
    im2 <- imsub(im, x > 820 & x < 870, y > 855 & y < 885)
    
    save.image(im2, output_path)
    
    tokens <- ocr_data(output_path)[1,1] %>% 
      gsub(pattern = "o",replacement = "0") %>%
      gsub(pattern = "O",replacement = "0") %>%
      as.numeric
    tokens <- ifelse(is.na(tokens), 8 , tokens)
    
    file.remove(output_path)
    return(tokens)
  }
}
get_scraps <- function(im_name, directory){
  
  input_path <- paste0(directory, im_name)
  output_path <- paste0(directory, "aux_scraps.jpg")
  
  im <- load.image(input_path)
  if(width(im) == 1080 & height(im) == 2220){
    im2 <- imsub(im, x > 820 & x < 870, y > 960 & y < 995)
    
    save.image(im2, output_path)
    
    scraps <- ocr_data(output_path)[1,1] %>% 
      gsub(pattern = "o",replacement = "0") %>%
      gsub(pattern = "O",replacement = "0") %>%
      as.numeric
    file.remove(output_path)
    return(scraps)
  }
}
get_object_one <- function(im_name, directory){
  
  input_path <- paste0(directory, im_name)
  output_path <- paste0(directory, "aux_object.jpg")
  
  im <- load.image(input_path)
  if(width(im) == 1080 & height(im) == 2220){
    
    im2 <- imsub(im, x == 230, y == 1180)

    im2_hero <- imsub(im, x > 310 & x < 650, y > 1095 & y < 1125)
    save.image(im2_hero, output_path)
    
    hero_one <- ocr_data(output_path)[1,1]
    object_one <- as.data.frame(im2)
    
    info1 <- cbind(hero = hero_one,object_one %>% spread(cc,value))
    file.remove(output_path)
    return(info1)
    
  }
}
get_object_two <- function(im_name, directory){
  
  input_path <- paste0(directory, im_name)
  output_path <- paste0(directory, "aux_object.jpg")
  
  im <- load.image(input_path)
  if(width(im) == 1080 & height(im) == 2220){
    
    im2 <- imsub(im, x == 230, y == 1325)
    
    im2_hero <- imsub(im, x > 310 & x < 650, y > 1240 & y < 1270)
    save.image(im2_hero, output_path)
    
    hero_one <- ocr_data(output_path)[1,1]
    object_one <- as.data.frame(im2)
    
    file.remove(output_path)
    info1 <- cbind(hero = hero_one,object_one %>% spread(cc,value))
    return(info1)
    
  }
}
extract_all_info <- function(im_name, directory){
  
  code <- as.character(strsplit(im_name, "_")[[1]][2])
  
  tokens <- get_tokens(im_name, directory)
  scraps <- get_scraps(im_name, directory)
  object_one <- get_object_one(im_name, directory)
  object_two <- get_object_two(im_name, directory)
  
  basic_out <- data.frame("Code" = code,
                          "Item" = c("Tokens","Scraps"),
                          "Value" = c(tokens,scraps),
                           stringsAsFactors = F)
  
  objects_out <- data.frame(code, bind_rows(object_one, object_two))
  names(objects_out) <- c("Code", "Hero", "Red","Green","Blue")
  
  AUX <-  list("CURRENCIES" = basic_out, 
               "ITEMS" = objects_out)
  return(AUX)
  
}

##########  DATA LOADING AND DEFINITION  ###############

data_directory <- "./data/"
data_files <- list.files(data_directory)
if("basic.txt" %in% data_files){
  basic <- read.table("./data/basic.txt", sep = ";", dec = ".", header = T, stringsAsFactors = F)
} else {
  basic <- data.frame("Code" = NA, 
                      "Item" = NA, 
                      "Value" = NA, stringsAsFactors = F)
}

if("items.txt" %in% data_files){
  items <- read.table("./data/items.txt", sep = ";", dec = ".", header = T, stringsAsFactors = F)
} else {
  items <- data.frame("Code" =NA,
                      "Hero" = NA,
                      "Red" = NA,
                      "Green" = NA,
                      "Blue" = NA, stringsAsFactors = F)
}


directory <- pic_directory <- "./pic/"
files <- list.files(pic_directory)

codes <- sapply(strsplit(files, "_"),function(x) x[[2]])
new_codes <- unique(c(codes[!codes  %in% basic$Code], codes[!codes  %in% items$Code]))

new_files <- files[codes %in% new_codes]

if(new_files > 0) {
  OUTPUT <- list()
  for(ii in seq_along(new_files)){
    OUTPUT[[ii]] <- extract_all_info(new_files[[ii]], pic_directory)
    cat(ii, "/", length(new_files), "\n")
  }
  
  
  basic.temp <- bind_rows(lapply(OUTPUT, function(x) x[[1]]))
  basic <- bind_rows(basic, basic.temp) %>% filter(!is.na(Code)) %>% unique
  
  write.table(x = basic, file = "./data/basic.txt",append = F, sep = ";",dec = ".",row.names = F,col.names = T)
  
  
  items.temp <- bind_rows(lapply(OUTPUT, function(x) x[[2]]))
  items <- bind_rows(items, items.temp) %>% filter(!is.na(Code)) %>% unique
  
  write.table(x = items, file = "./data/items.txt",append = F, sep = ";",dec = ".",row.names = F,col.names = T)
}





basic.plot <- basic %>% 
  count(Value, Item) %>%
  group_by(Item) %>%
  mutate(prop = n/sum(n))

expected_data <- data.frame("Item" = c("Scraps", "Tokens"),
                            "Exp" = c(0.025, 0.1))


ggplot(basic.plot, aes(x = Value , y = prop, fill = Item)) +
  geom_bar(stat = "identity") + 
  facet_grid(.~Item, scales = "free") +
  scale_y_continuous(labels = scales::percent,breaks = seq(0,1,by =0.025)) +
  scale_x_continuous(breaks = c(seq(5,15, by = 1), seq(20,60, by = 5))) +
  geom_hline(aes(yintercept = Exp, colour = Item), data =expected_data) + 
  labs(title = "% of rewards in chest chest",
       x = "Amount of currency per chest",
       y = "% of chance to get")
  

items.plot <- items %>% count(Hero) %>%
  mutate(prop = n/sum(n))

expected_data <- data.frame("Hero" = unique(items.plot$Hero),
                            "Exp" = 1/14) 

ggplot(items.plot %>% arrange(Hero), aes(x = Hero , y= prop)) +
  geom_bar(stat = "identity", fill = "#00BFC4") +
  geom_hline(aes(yintercept = Exp), colour = "#00BFC4", data = expected_data) + 
  scale_y_continuous(labels = scales::percent) +
  coord_flip()


dates <- basic %>% 
  mutate(date = substr(Code, 0, 8)) %>%
  mutate(Date = as.Date(date, format = "%Y%m%d")) %>% 
  distinct(Date, Code) %>%
  count(Date)

ggplot(dates, aes(x = Date, y = n)) +
  geom_line(colour = "#00BFC4") +
  # geom_bar(stat = "identity", fill = "#00BFC4") +
  geom_text(aes(label = n))



colours <- items[,c("Red", "Green", "Blue")]


pca <- prcomp(colours)

summary(pca)
ggbiplot(pca, circle = T, obs.scale = 1, var.scale = 1)


aux2 <- kmeans(pca$x[,1:2], centers = 5)
aux2$cluster %>% table


aux <- kmeans(colours,centers = 6)
aux$cluster %>% table








