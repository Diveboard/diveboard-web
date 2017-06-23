package diveboard;



import diveboard.CommonActions;
//import org.testng.annotations.Test;


public class SimpleDiveActions extends CommonActions {
	
	
	public static String url_new_dive;
	public static String graph_small = "M1,15L1,15L2,82L183,82L185,15L189,15L189,110L1,110L1,15";
	public static String prifile_graph = "M25,20L25,20L30,272L601,272L607,20L620,20L25,20";
	public static String date = "2011-07-28";
	public static String time_hrs = "22";
	public static String time_mins = "59";
	public static String dive_duration = "45";
	public static String max_depth_in_ft = "25"; // == 7,6 meters
	public static String max_depth_in_mt ="7.6";
	
	
	protected void createSimpleNewDive() throws InterruptedException {
		System.out.println("Creating simple dive..");
		sel.open("/");
		sel.click("create_dive_2");
		waitForVisible(saveDiveBut);
		sel.click(tab_map);
		waitForVisible("id=createnewspot_back");
		
		//LOCATION  creating a new spot

		System.out.println("creating a new spot.. ");
	
		// Chose Russia
		sel.type("spot-country", "");
		sel.typeKeys("spot-country", "Russ");
		System.out.println("waiting for spot-country drop down...");
		
		waitForElement("//body/ul/li[2]/a");
			
		sel.mouseOver("//body/ul/li[2]/a");
		sel.click("//body/ul/li[2]/a");
		
		waitForElement("//img[@src='/img/flags/ru.gif']"); //russian flag
		
		
		type("spot-location", "Test1");
		type("spot-name", "Test2");
		type("spot-region", "Test3");
		click("spot-lat");
		type("spot-lat", "68.52401");

		type("spot-long", "108.31875600000001");
		click("spot-precision");
		

		verifyTrue(sel.isElementPresent("css=div[title=Zoom out]"));
		verifyTrue(sel.isElementPresent("css=div[title=Zoom in]"));
	
	
		sel.click(tab_overview);
		// Profile
		
		//* with only the mandatory information
	
		Thread.sleep(1000);
	
	
	
		type("wizard-date", date);
		
	
		type("wizard-time-in-hrs", time_hrs);
		type("wizard-time-in-mins", time_mins);
		type("wizard-duration-mins", dive_duration);
		type("wizard-max-depth", max_depth_in_ft);
		
		click(saveDiveBut);
		
		
		
	
		waitForNotVisible("id=file_spinning");

		
		waitForDiveLink();
		
		url_new_dive=sel.getLocation();
		
		System.out.println("New Dive with only mandatory info created. " + url_new_dive);

		
	}
	

	


	public void viewDiveInImperial() throws Exception {
		System.out.println("View dive in Imperial");
	
		sel.open(url_new_dive);
		//* Dive information displayed on main page : date, time, depth, duration, temperatures, notes, fishes [if available - if not then correctly displayed]
		sel.waitForPageToLoad("300000");
		Thread.sleep(1000);
		assertEquals(sel.getText("//div[@id='tab_overview']/div[1]/ul/li[2]"), "Max Depth: "+max_depth_in_ft+"ft Duration:"+dive_duration+"mins");

	
		viewDive();
	

	System.out.println("Dive in Imperial checked");

	}


	protected void viewDiveInMetric()  throws Exception {
		System.out.println("View dive in Metric");	

		open(url_new_dive);
			sel.waitForPageToLoad("300000");
			waitForVisible("css=div.double_box");
			assertEquals(sel.getText("//div[@id='tab_overview']/div[1]/ul/li[2]"), "Max Depth: "+max_depth_in_mt+"m Duration:"+dive_duration+"mins");
			
			
			viewDive();
			
			
			
			
			
			
			System.out.println("Dive in Metric checked");	

	}
		
 private void viewDive() throws InterruptedException
 {
	// String innerhtml = sel.getEval("window.document.getElementById(\"graph_small\").innerHTML");
	
		
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf('" + graph_small + "') > 0"));
		
	 verifyEquals(sel.getText("//div[@id='tab_overview']/div[1]/ul/li[1]"), "Date: "+ date +" - " + time_hrs + ":"+time_mins);
	
		//Now If there are no notes, there should not be the diver's notes frame
		//verifyEquals(sel.getText("css=div.divers_comments"), "Diver's Notes");
		verifyFalse(sel.isElementPresent("css=div.divers_comments"));
	
	// verifyTrue(sel.isTextPresent("No pictures for this dive"));
		verifyEquals(sel.getText("css=div.triple_box > p"), "No pictures for this dive");
		verifyTrue(sel.getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[3]").equalsIgnoreCase("SPECIES SPOTTED: No species spotted"));
	//	verifyTrue(sel.isTextPresent("Species spotted: No species spotted"));
	//	verifyTrue(sel.isTextPresent("Recent Divers in Test1"));
	
	
		verifyTrue(sel.isElementPresent("//div[@id='tab_overview']/div[3]/div[1]/ul/li[1]/a/img"));
		verifyTrue(sel.isElementPresent("//div[@id='tab_overview']/div[3]/div[2]/ul/li[1]/a/img"));
		
		//location
		verifyEquals("Test2", sel.getText("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span"));
		verifyEquals("Russian Federation", sel.getText("country_title"));
		
		verifyEquals("Test1", sel.getText("//li[2]/a[2]"));
		verifyEquals("Test3", sel.getText("//li[2]/a[3]"));
	//	verifyTrue(sel.isTextPresent("Test1"));
	//	verifyTrue(sel.isTextPresent("Test3"));
		
	//	verifyFalse(sel.isTextPresent("Gulf grouper"));
		
		verifyFalse(sel.isElementPresent("featured_pic"));
		
		verifyTrue(sel.isVisible("id=graph_small"));
		verifyTrue(sel.isElementPresent("css=img.tooltiped-js"));
		verifyTrue(sel.isElementPresent("css=a[name=modal] > img.tooltiped-js"));
		verifyTrue(sel.isElementPresent("css=#privacy > img.tooltiped-js"));
		
		verifyTrue(sel.isElementPresent("css=div.thumbs_up_icon"));
		
		verifyTrue(sel.isElementPresent("css=div.thumbs_up_icon"));
		verifyTrue(sel.isElementPresent("css=span.liketext"));
		verifyTrue(sel.isElementPresent("css=span.btnText"));
	
		
		// * album of all pictures/videos on "pictures" tab not exists
		 verifyFalse(sel.isElementPresent("tab_pictures_link"));


//profile
		sel.click("tab_profile_link");
		
		waitForElement("//div[@id='tab_profile']/h1");
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graphs\").innerHTML.indexOf(\"" + prifile_graph + "\") > 0"))	;
		
	//	 innerhtml = sel.getEval("window.document.getElementById(\"graphs\").innerHTML");
	}

 public void changeToPrivate() throws InterruptedException {
	
	if (sel.isElementPresent("//img[@alt='Public']")) {
		sel.click("css=#privacy > img.tooltiped-js");
		waitForVisible("//img[@alt='Private']");
//		waitForElement("css=div.double_box > a > img"); //fb comment for private dive
		System.out.println("Dive is changed to Private");
	}
	else  if(sel.isElementPresent("//img[@alt='Private']"))
			System.out.println("Dive is already Private");	

	
	
}
	

 public void changeToPublic() throws InterruptedException {
	if (sel.isElementPresent("//img[@alt='Private']")) {
		sel.click("css=#privacy > img.tooltiped-js");
		waitForVisible("//img[@alt='Public']");
	
	//	waitForElement("css=label.desc"); //fb comment for public dive
		
		System.out.println("Dive is changed to Public");
	}
	else  if(sel.isElementPresent("//img[@alt='Public']"))
			System.out.println("Dive is already Public");	
			
}

}
