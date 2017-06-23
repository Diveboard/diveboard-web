
import org.junit.Test;
import diveboard.SimpleDiveActions;

public class MyPrivateDive extends SimpleDiveActions{
	@Test
	public void test_PrivateDive() throws Exception {
	
//	fb_user_id = createTestFBUser();
//	loginTempFBUser();
		
	register();
	changeUnitSystemToImperial();
	createSimpleNewDive();
	
	changeToPrivate();
	changeUnitSystemToMetric();
	viewDiveInMetric();
	
	changeToPublic();
	checkPublicButtons();
	
	logout();
	viewDiveInMetric();
	//loginFB();
	accLogin();
	open(url_new_dive);
	sel.waitForPageToLoad("30000");
//	waitForVisible("css=label.desc");
	//wait for FB frame to load
//	waitForVisible("//table[@class='connect_widget_interactive_area']");  
	
	changeToPrivate();
	
	logout();
	ViewPrivateNotLogin();
	ViewNoDives();	
//	deleteTempFBUser(fb_user_id);
	closeBrowser();

	}

	private void checkPublicButtons() {
		verifyTrue(sel.isElementPresent("//div[@id='plusone']/div/a"));
		verifyTrue(sel.isElementPresent("aggregateCount"));
		verifyTrue(sel.isElementPresent("css=div.msgIcon"));
	}


	private void ViewNoDives() throws InterruptedException {
		System.out.println("View acc when not logged in..");	
		open(user_url);
				
		
		waitForElement("css=div.main_content_box.logbook_profile");
		
		verifyTrue(sel.getText("css=span.header_title").equals(fb_user_name + "'s"));
		
		
		verifyTrue(sel.getText("css=span.half_box_data").equals("0")); //# Dives on Diveboard:0

		verifyTrue(sel.getText("//div[@id='profile_stat']/ul/li[3]/span").equals("1")); //# Total number of dives:1
		verifyTrue(sel.getText("css=ul.editable > li").equals("There are no public dives !"));
	}


	private void ViewPrivateNotLogin() throws InterruptedException {

		System.out.println("View private dive when not logged in..");	
		sel.open(url_new_dive);
		waitForElement("css=h1");
	
		verifyTrue(sel.getText("css=h1").equals("Dive unavailable"));
		verifyTrue(sel.isTextPresent("Dive unavailable Sorry this dive is not public but feel free to check out other dives from" + fb_user_name + " Bubbling on Diveboard"));
		
		
	}



	
}