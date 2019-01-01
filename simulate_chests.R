simulate_chest <- function(amount){
  
 tokens <- 7/10*runif(n = amount, min = 5, max = 14)
 scraps <- runif(n = amount, min = 20, max = 59)
 items1 <- sample(c(10,25,75,150,300), size= amount, replace=TRUE, prob=c(0.756,0.199,0.0378, 0.00511, 0.00204))
 items2 <- sample(c(10,25,75,150,300), size= amount, replace=TRUE, prob=c(0.756,0.199,0.0378, 0.00511, 0.00204))
 
 value <- tokens + scraps + items1 + items2
 return(data.frame("values" = value))
 
}

set.seed(1234)
simulation <- simulate_chest(100000)


out <- simulation %>% 
  mutate(values = ifelse(values > 250, 250, values)) %>%
  count(values = round(values/5)*5) %>%
  mutate(prop = n/sum(n))
  

ggplot(out, aes(x = values, y = prop)) +
  geom_bar(stat = "identity", fill = "#00BFC4") +
  geom_vline(xintercept= mean(simulation$values)) + 
  annotate("text", x = mean(simulation$values) + 10, y = 0.03, label = round(mean(simulation$values))) + 
  annotate("text", x = mean(simulation$values) + 10, y = 0.035, label = "Average") + 
  geom_vline(xintercept= quantile(simulation$values,0.10)) + 
  annotate("text", x = quantile(simulation$values,0.10) + 10, y = 0.025, label = round(quantile(simulation$values,0.10))) +
  annotate("text", x = quantile(simulation$values,0.10) + 10, y = 0.030, label = "10%") +
  geom_vline(xintercept= quantile(simulation$values,0.90)) + 
  annotate("text", x = quantile(simulation$values,0.90) + 10, y = 0.025, label = round(quantile(simulation$values,0.90))) +
  annotate("text", x = quantile(simulation$values,0.90) + 10, y = 0.030, label = "90%") +
  scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = seq(40, 250, by = 30)) +
  labs(x = "Scrap Value per chest", y ="Chances to get", title = "Distribution of value per chest", subtitle = "Based on simulation")

ggsave(filename = "chest_value.jpg", path = "./images_report")

