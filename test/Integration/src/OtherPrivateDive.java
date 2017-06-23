
import org.junit.Test;  


import diveboard.SimpleDiveActions;

public class OtherPrivateDive extends SimpleDiveActions{
	
	// test the permissions between two accounts
	public static String smn_private_dive = "ksso/488";
//	public static String smn_draft_dive = "http://stage.diveboard.com/ksso/488";
	
//	public static String other_user_id;
	public static String other_user_puplic_dive;
	public static String other_user_private_dive;
	public static String other_user_draft;
	
	@Test
	public void test_OtherDive() throws Exception {
		

	register();
	create_other_user_puplic_dive();
	create_other_user_private_dive();
	create_other_user_draft();
	
	logout();
	
	fb_user_id= createTestFBUser();
	loginTempFBUser();
	
	view_other_public();
	view_other_private(other_user_private_dive);
	view_other_private(other_user_draft);
	view_other_private(smn_private_dive);
	
	logout();
	
	view_other_public();
	view_other_private(other_user_private_dive);
	view_other_private(other_user_draft);
		
	
	deleteTempFBUser(fb_user_id);

	sel.stop();
	}
	

	private void view_other_private(String link) {
		sel.open(link);
		sel.waitForPageToLoad("50000");
		verifyEquals("Dive unavailable", getText("css=h1"));
		verifyTrue(getText("css=div.no_content").startsWith("Dive unavailable Sorry this dive is not public but feel free to check out other dives from"));
	//	verifyTrue(sel.isTextPresent("Sorry this dive is not public but feel free to check out other dives"));
	//	verifyTrue(sel.isTextPresent("Bubbling on Diveboard:"));
		System.out.println("Unavailable dive checked");
	}

	private void view_other_public() throws InterruptedException {

		open(other_user_puplic_dive);
		sel.waitForPageToLoad("500000");
		waitForElement("css=span.header_title");
		verifyTrue(isElementPresent("id=add_buddy"));
		verifyTrue(isElementPresent("SnapABug_bImg"));
		verifyTrue(isElementPresent("country_title"));
		verifyTrue(isElementPresent("link=Gozo"));
		verifyTrue(isElementPresent("link=Mediterranean Sea"));
	//	verifyTrue(isElementPresent("css=img[alt=Add as buddy]"));
		
		verifyEquals("Blue Hole", getText("css=span.header_title"));
		waitForElement("css=div.main_content_header ");
		verifyTrue(isElementPresent("css=img.tooltiped-js"));
		
		verifyTrue(isElementPresent("css=span.liketext"));
		
		verifyTrue(isElementPresent("css=div.thumbs_up_icon"));
		verifyTrue(isElementPresent("css=div.msgIcon"));
		verifyText("//div[@id='tab_overview']/div[1]/ul/li[2]", "Max Depth: 25m Duration:45mins");
		
		waitForVisible("id=graph_small");
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf(\"" + graph_small + "\") > 0"));
		click(tab_profile);
		waitForVisible("id=graphs");
		
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graphs\").innerHTML.indexOf(\"" + prifile_graph + "\") > 0"));
		System.out.println("Other public dive checked");	
		
		
	}

	protected void create_other_user_puplic_dive() throws InterruptedException {
		sel.open("/");
		waitForElement("create_dive_2");
		click("create_dive_2");
	//	waitForElement("spotsearch");
		waitForVisible(saveDiveBut);

		//LOCATION  Search your Dive Spot: 
		
		System.out.println("Fill in spotsearch..");
		
		spotSearch("blu ho go",2);
	
		// Profile
		click(tab_overview);
		
		//* with only the mandatory information
	//	click("wizard-date");
	//	click("css=a.ui-state-default.ui-state-hover");
		type("wizard-date", date);
		type("wizard-time-in-hrs", "22");
		type("wizard-time-in-mins", "59");
		type("wizard-duration-mins", "45");
		type("wizard-max-depth", "25");
		
	//	click("link=Dive Notes");
		type("wizard-dive-notes", "Test public dive");
		
		click(saveDiveBut);
	
	//	waitForVisible("css=span.fwb.fcb");  //changed from mask
	//	waitForVisible("css=label.desc"); 
		
		waitForNotVisible("id=file_spinning");
		waitForDiveLink();
		
		
		//wait for Dive Editor to close
		for (int second = 0;; second++) {
			if (second >= minute) fail("FAIL: Element id=dialog is still on page " + sel.getLocation());
			try { if (!isElementPresent("id=dialog")) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		
		}
	//	waitForVisible("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span");
		verifyTrue(isElementPresent("//img[@alt='Public']"));
		verifyTrue(getText("css=span.header_title").equals("Blue Hole"));
		waitForDiveLink();
	//	String host = sel.getEval("window.document.domain");
		other_user_puplic_dive = sel.getLocation();
		System.out.println("New Public Dive created. " + other_user_puplic_dive);
		
	}
	
	
	protected void create_other_user_private_dive() throws InterruptedException {
	//	sel.open("/");
		click("create_dive_2");
	//	waitForElement("spotsearch");
		waitForVisible(saveDiveBut);

		//LOCATION  Search your Dive Spot: 
		System.out.println("fill in spotsearch with 'gho indon'");
		
		spotSearch("gho indon",1);
	
		waitForElement("//img[@src='/img/flags/id.gif']"); //indonesia flag
		
		System.out.println("'Ghost Bay, Amed, Laut Bali, Indonesia' - found ");
		
		
		/*
		for (int second = 0;; second++) {
			if (second >= minute) fail("could not find text 'Search for another spot or correct data'");
			try { if ("Search for another spot or correct data".equals(getText("//div[@id='correct_submit_spot_data']/label"))) break; } catch (Exception e) {}
			Thread.sleep(1000);
		}
		*/
	//	click("wizard_next");

		click(tab_overview); 
		waitForVisible("wizard-surface-temperature");
		
		// Profile
//		click("link=Profile Data");
		
		//* with only the mandatory information
	//	click("wizard-date");
	//	click("css=a.ui-state-default.ui-state-hover");
		type("wizard-date", date);
		type("wizard-time-in-hrs", "22");
		type("wizard-time-in-mins", "59");
		type("wizard-duration-mins", "45");
		type("wizard-max-depth", "25");
		
	//	click("link=Dive Notes");
		type("wizard-dive-notes", "Test private dive");
		
		click(saveDiveBut);
	//	waitForVisible("css=span.fwb.fcb");  //changed from mask
		waitForNotVisible("id=file_spinning");
		waitForDiveLink();
	//	waitForVisible("css=label.desc"); 
		//wait for Dive Editor to close
		for (int second = 0;; second++) {
			if (second >= minute) fail("FAIL: Element id=dialog is still on page " + sel.getLocation());
			try { if (!isElementPresent("id=dialog")) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		
		}
		
	//	waitForElement("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span");
	
		changeToPrivate();
		//check if counters not present
		verifyFalse(isElementPresent("aggregateCount"));  
		verifyFalse(isElementPresent("//div[@id='plusone']/div/a")); 
		verifyFalse(isElementPresent("css=div.msgIcon"));  
	
		verifyTrue(getText("css=span.header_title").equals("Ghost Bay"));
		
	//	String host = sel.getEval("window.document.domain");
		other_user_private_dive = sel.getLocation();
		System.out.println("New Private Dive created. " + other_user_private_dive);
		
	}
	
	

	protected void create_other_user_draft() throws InterruptedException {
		sel.open("/");
		click("create_dive_2");
	
		waitForVisible(saveDiveBut);
	
		type("wizard-date", date);
		type("wizard-time-in-hrs", "22");
		type("wizard-time-in-mins", "59");
		type("wizard-duration-mins", "45");
		type("wizard-max-depth", "25");
		
		//Notes

		type("wizard-dive-notes", "Test draft");
		// Save
		click(saveDiveBut);
		waitForNotVisible("id=file_spinning");
	//	waitForVisible("//div[@id='main_content_area']/div[3]/a/img");  //changed from mask
	//	waitForElement("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span");
	
		

		verifyTrue(getText("css=span.header_title").equals("New Dive"));
		verifyTrue(isElementPresent("//img[@alt='Private']"));
		waitForDiveLink();
	//	String host = sel.getEval("window.document.domain");
		other_user_draft = sel.getLocation();
		System.out.println("New draft created. " + other_user_draft);
		
	}
	
	
	

	
	
}