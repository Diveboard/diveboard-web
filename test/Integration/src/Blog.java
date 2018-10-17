import org.junit.*;  


import diveboard.CommonActions;


public class Blog extends CommonActions {
	
	@Test
	public void blog_test() throws InterruptedException {
		
		
		System.out.println("Checking blog..");
		open("https://www.diveboard.com/blog/");
		//sel.waitForPageToLoad("30000");
		
		checkMobileBlog();
		checkPages();
		checkMainMenuItems();
		
		closeBrowser();
		
		
		
	}

	private void checkMainMenuItems() throws InterruptedException {
		System.out.println("Checking Main Menu Items..");
		for(int i=2; i < 10; i++) //clicking-checking     * Home		    * Discover		    * Divers		    * Events		    * News		    * Sea Life		    * Spots		    * Technique

		{
		click("//div/div/div/ul/li["+i+"]/a");
		waitForElement("css=ul");
		//verifyTrue(isElementPresent("css=ul"));
		verifyTrue(isElementPresent("content"));
		verifyTrue(isElementPresent("css=div.tagcloud"));
		verifyTrue(isElementPresent("css=img.png"));
		verifyTrue(isElementPresent("css=div.menu"));
		verifyTrue(getText("css=div.main_menu_content.menu").contains("Home News Sea Life Technique Spots Events Divers Discover Gear"));
		verifyTrue(isElementPresent("css=div.textwidget > a > img"));
		assertTrue(isElementPresent("edit-search-theme-form-keys"));
		verifyTrue(isElementPresent("css=#widget_tag_cloud > h2.blocktitle"));
		verifyTrue(isElementPresent("css=div.clearfix"));
		verifyTrue(isElementPresent("css=span.liketext"));
		verifyTrue(isElementPresent("link=Switch to our mobile site"));
		verifyNotEquals("", getText("//div[@class='entry']")); //articles can be read
		}
		
	}

	private void checkPages() {
int pages =0;
		
		do
		{ 
			verifyTrue(isElementPresent("css=ul"));
			verifyTrue(isElementPresent("css=div.nav"));
			verifyTrue(isElementPresent("css=img[alt='explore']"));
			verifyTrue(isElementPresent("css=img[alt='sign up']"));
			verifyTrue(isElementPresent("content"));
			verifyTrue(isElementPresent("css=div.tagcloud"));
			verifyTrue(isElementPresent("css=img.png"));
			verifyTrue(isElementPresent("css=div.menu"));
			verifyTrue(getText("css=div.main_menu_content.menu").contains("Home News Sea Life Technique Spots Events Divers Discover Gear"));
			verifyTrue(isElementPresent("css=div.textwidget > a > img"));
			assertTrue(isElementPresent("edit-search-theme-form-keys"));
			verifyTrue(isElementPresent("css=#widget_tag_cloud > h2.blocktitle"));
			verifyTrue(isElementPresent("css=div.clearfix"));
			verifyTrue(isElementPresent("css=span.liketext"));
			verifyTrue(isElementPresent("link=Switch to our mobile site"));
			verifyNotEquals("", getText("//div[@class='entry']")); //articles can be read
			if(isElementPresent("link=»"))
			{
				click("link=»");
				//sel.waitForPageToLoad("300000");
				pages++;
				System.out.println("Open "+pages+" page");
			}
		}while(isElementPresent("link=»")&& pages<20);
			
		
	}

	private void checkMobileBlog() throws InterruptedException {
		System.out.println("Switch to our mobile site..");
		click("link=Switch to our mobile site");
		waitForElement("css=ul");
		verifyEquals(getText("css=ul"),"AboutJapan scuba catastrophe recovery effort");
		verifyEquals(getText("css=h1"),"Recent posts");
		verifyNotEquals("", getText("css=div.entry"));
		verifyTrue(isElementPresent("link=Read more"));
		System.out.println("Switch to our desktop site..");
		click("link=Switch to our desktop site");
		//sel.waitForPageToLoad("30000");
	}

}
