test:
	zcat ../../t/wex.gz | wex2link --params > wx.links
	linkTables --titletext wx.links wx
	linkBags wx.links wx

clean:
	rm -f wx.* wikiline.bad
