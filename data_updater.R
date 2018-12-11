if(!require(ggbiplot)){install.packages("ggbiplot")}
if(!require(plotly)){install.packages("plotly")}
if(!require(tidyverse)){install.packages("tidyverse")}
if(!require(magrittr)){install.packages("magrittr")}
if(!require(ggplot2)){install.packages("ggplot2")}
if(!require(imager)){install.packages("imager")}
if(!require(tesseract)){install.packages("tesseract")}


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

if(length(new_files) > 0) {
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

rm(list =ls())