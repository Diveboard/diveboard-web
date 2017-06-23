import org.junit.Test;

import diveboard.CommonActions;

public class Explore extends CommonActions {
	public static String country = "France";
	public static String countryRu = "Франция";
	public static String location = "Central Adriatic, Adriatic Sea, Croatia";
	@Test
	public void test_explore() throws Exception {
		
	
		searchCountry();
		spotsClick();
		sel.stop();
	}

	




	private void searchCountry() throws InterruptedException {
		// TODO Auto-generated method stub
		
	
	sel.open("/explore");
	sel.waitForPageToLoad("50000");
	

	waitForVisible("menu_bar_search");
	System.out.println("Explore " + country);
	sel.type("menu_bar_search", country);
	sel.click("css=input[type=image]"); //click search
	
	
	
	waitForVisible("id=search_text_field");
	
	
	
	
	for (int second = 0;; second++) {
		if (second >= minute) fail(country +" is not value for search_text_field on page " + sel.getLocation());
		try { if (sel.getValue("id=search_text_field").equalsIgnoreCase(country)) 
						break; } 
		catch (Exception e) {}
		Thread.sleep(1000);
		}	
	

	sel.click("id=search_text_button");
//	String wtf = sel.getText("//li[@id='search-location-0']/div[2]/span");
	
	for (int second = 0;; second++) {
		if (second >= minute) fail(country +" is not visible on css=span.ls_results_name " + sel.getLocation());
		try { if (sel.getText("//li[@id='search-location-0']/div[2]/span").equalsIgnoreCase(country)
				|| sel.getText("//li[@id='search-location-0']/div[2]/span").equalsIgnoreCase(countryRu)) 
			break; } 
		catch (Exception e) {}
		Thread.sleep(1000);
		 // sometimes search_text_button  is not pressed for unknown reason I give it second chance:
		if (second == 15) sel.click("id=search_text_button");
		}	
	
	}
//	verifyEquals(sel.getText("css=span.ls_results_name"), country);
	
	private void spotsClick() throws InterruptedException {
	
	
	sel.click("search-location-0");
	//red spot
	System.out.println("Open red spot..");
	waitForElement("//div[@style[contains(.,'m3.png')]]");
	sel.click("//div[@style[contains(.,'m3.png')]]");
	//yellow spot
	System.out.println("Open yellow spot..");
	waitForElement("//div[@style[contains(.,'m2.png')]]");
	sel.click("//div[@style[contains(.,'m2.png')]]");
	//blue spot
	System.out.println("Open blue spot..");
	waitForElement("//div[@style[contains(.,'m1.png')]]");
	sel.click("//div[@style[contains(.,'m1.png')]]");
	
	sel.click("ls_spot_btn");
	waitForElement("//div[3]/div/div/ul/li");
	sel.click("//div[3]/div/div/ul/li");
	waitForElement("//img[contains(@src,'iw_close.gif')]");
	verifyEquals(sel.getText("css=h4"), location);
	System.out.println("Spot location verifyed");
	sel.click("//img[contains(@src,'iw_close.gif')]");
		
	}
	}

