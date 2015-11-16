# Classic Lenses

---

## Introduction

This is Project 5 for Udacity's iOS Developer Nanodegree.

This is an open-ended project, designed to give us an opportunity to build a new app from ground up.

Main objectives of this project:

* Build sophisticated and polished user interfaces
* Downloading data from network resources
* Persisting state on device using Core Data
* Researching and integrating new libraries

I have been researching on camera lenses lately and found that it was fairly troublesome to gather data from different lenses manually to analyse their pros and cons. So for this project, I decided to gather a list of classic Voigtlander lenses into an app, together with their current prices and sample photos taken with them. This makes it much easier to browse through the characteristics of these lenses and compare between them.

There are two main sources of networked data:
* Flickr - for sample photos taken with the selected lens
* Scraping Hub - I wrote some simple spiders to crawl some websites for lens and price data, and the results are hosted on Scraping Hub which provides a nice REST API for fetching these results

The app starts off with a collection view of lenses together with their representative prices. Upon selecting a lens, three tabs are presented to the user:
* Info - this shows info about the lens such as its focal length, aperture size, minimum focus distance, weight and length
* Sample photos - this fetches photos taken with the selected lens from Flickr
* Prices - this shows the prices of the selected lens from Amazon and B&H

## Requirements

You will need these installed on your Mac:

* Xcode 7.1, Swift 2