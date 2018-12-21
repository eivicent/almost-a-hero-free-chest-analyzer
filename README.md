# Almost a Hero - Free Chest Analysis
### Motivation
Almost a Hero is Free-To-Play idle-RPG mobile game. As many FTP games, users can purchase lootboxes that awards currencies and items that are needed to progress in game. It is also common that these kind of games offer a FREE lootbox every [X] amount of hours to help retaining the user and creating the habit of connecting.

After having played this game (and a lot other games) for quite some time, I wanted to determine what is the value of this free lootbox and use it to do a small data project.

For this, I have been gathering screenshots for ~40 days and analyzed them with `imager`and `tesseract` packages

### Data
One free lootbox is available every 4 hours but it can be reduced to 1h, allowing me to open a lot of chests daily and gather the maximum data as possible.

![](./images_report/daily_chests.jpg)


In total:

Chests|Days
------|------
488|46

Each lootbox contains:
- Guaranteed amount of *Scraps*  [20-60]
- Guaranteed amount of *Tokens* [5-15]
- *Rarity* (associated to the colour of the border) and *Hero* of each item

For each lootbox, I was taking a screenshot of the rewards screen and reading the following information:

<img src="./images_report/example_screenshot.jpg" width="100" align = "middle"/>

### Process
Text and numbers were extracted directly from the parts of the screenshot with function `tesseract::ocr_data()`

Rarity of the items was exctracted by selecting 1 pixel of the border of each and reading its RGB composition




