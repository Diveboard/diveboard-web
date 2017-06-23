
import org.junit.Test;

import diveboard.SimpleDiveActions;

public class CreateSimpleNewDive  extends SimpleDiveActions {

	public String test_note = "a test note for this dive at l'chelle, near the village of  \n<a> wonderful dive </a>; with me & everyone !";
	
	
	@Test
	public void test_CreateSimpleNewDive() throws Exception {
		
	//	fb_user_id = createTestFBUser();
	//	loginTempFBUser();
		register();
				
		changeUnitSystemToImperial();
		createSimpleNewDive();
		viewDiveInImperial();
		
		changeUnitSystemToMetric();
		viewDiveInMetric();
			
		deleteCurrentDive(url_new_dive);
			
		
		bulkFromFile("C:\\test_data\\simple_dive.zxl");
	//	viewDiveInMetric(); //will fail until Bug #131 is solved
		
		deleteCurrentDive(url_new_dive);
		
		changeUnitSystemToImperial();
		bulkFromFile("C:\\test_data\\simple_dive.udcf");
	//	viewDiveInImperial();//will fail until Bug #131 is solved
	
	
		deleteCurrentDive(url_new_dive);
		
		closeBrowser();
		
	}

private void bulkFromFile(String path) throws InterruptedException {
	System.out.println("Upload simple dive from " + path);
	open(user_url + "/new?bulk=wizard");
	//	waitForVisible(saveDiveBut);
		waitForElement("//li[@class='tab_link active']/a[contains(text(),'Bulk upload')]");
	
	type("//input[@name='file']", path );
	
	waitForElement("css=span.qq-upload-file");

	verifyTrue(getText("css=span.qq-upload-file").contains("simple_dive."));
	waitForElement("css=option[value='0']");
	verifyTrue(getText("//option[@value='0']").contains("* 2011-07-28 22:59 45mins "));
	click("id=dive_list_selector_button");
	waitForDiveLink();	
	waitForVisible("id=main_content_area");
	waitForElement("//div[@class='jspPane']/ul/li/a");
	url_new_dive = url + sel.getAttribute("//div[@class='jspPane']/ul/li/a@href");
	System.out.println("Dive uploaded: " + url_new_dive);
//	url_new_dive = getWebDriver().getCurrentUrl() ;
	
}


	
	
}
