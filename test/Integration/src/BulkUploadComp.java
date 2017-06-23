
import def.constant;
import diveboard.*;
import org.junit.Test;  
import java.awt.Robot;
import java.awt.event.KeyEvent;

// need to import Test
//import junit.framework.TestCase;
import java.util.Random;

public class BulkUploadComp  extends CommonActions {

	
	public int minute = 60;
	public String graph_small =	"M1,15L1,15L2,25L3,29L4,33L5,36L6,39L7,42L8,45L8,50L9,52L10,60L11,64L12,65L13,66L14,66L15,67L16,67L17,67L18,67L19,67L20,64L21,67L22,67L23,67L23,67L24,67L25,68L26,68L27,67L28,68L29,68L30,67L31,67L32,65L33,66L34,68L35,68L36,66L37,67L37,67L38,68L39,68L40,65L41,64L42,65L43,65L44,65L45,66L46,66L47,65L48,65L49,67L50,67L51,67L52,66L52,67L53,71L54,72L55,69L56,73L57,75L58,79L59,81L60,82L61,79L62,79L63,82L64,84L65,81L66,79L66,80L67,84L68,91L69,94L70,95L71,94L72,96L73,100L74,103L75,102L76,99L77,100L78,100L79,99L80,98L81,97L81,92L82,83L83,76L84,75L85,73L86,78L87,79L88,79L89,79L90,77L91,76L92,73L93,73L94,72L95,73L95,71L96,65L97,59L98,56L99,51L100,50L101,48L102,46L103,49L104,49L105,52L106,52L107,54L108,55L109,51L109,47L110,48L111,48L112,49L113,50L114,49L115,48L116,47L117,47L118,48L119,48L120,50L121,50L122,51L123,51L124,53L124,53L125,54L126,53L127,55L128,53L129,50L130,50L131,47L132,46L133,46L134,46L135,44L136,45L137,47L138,47L138,46L139,48L140,45L141,44L142,44L143,45L144,42L145,40L146,39L147,36L148,36L149,36L150,35L151,36L152,36L153,34L153,33L154,31L155,31L156,32L157,31L158,30L159,30L160,30L161,27L162,28L163,28L164,27L165,27L166,27L167,26L167,25L168,27L169,27L170,28L171,29L172,28L173,26L174,23L175,22L176,23L177,23L178,24L179,25L180,25L181,27L182,27L182,28L183,28L184,27L185,26L186,25L189,15L1,15";
	public String prifile_graph = "M25,20L25,20L28,59L31,73L34,87L37,101L40,112L43,123L46,133L49,151L52,162L55,190L58,204L61,211L63,215L66,215L69,218L72,218L75,218L78,218L81,218L84,204L87,218L90,218L93,218L96,218L99,218L102,222L105,222L108,218L111,222L114,222L117,218L120,218L123,211L126,215L129,222L132,222L135,215L137,218L140,218L143,222L146,222L149,211L152,204L155,211L158,208L161,208L164,215L167,215L170,208L173,208L176,218L179,218L182,218L185,215L188,218L191,232L194,236L197,225L200,239L203,247L206,264L209,271L211,275L214,261L217,261L220,275L223,282L226,271L229,264L232,268L235,282L238,307L241,321L244,324L247,321L250,328L253,342L256,353L259,349L262,339L265,342L268,342L271,339L274,335L277,331L280,310L283,278L285,250L288,247L291,239L294,257L297,264L300,264L303,261L306,254L309,250L312,239L315,239L318,236L321,239L324,232L327,208L330,186L333,176L336,158L339,151L342,144L345,137L348,147L351,147L354,162L357,162L360,169L362,172L365,158L368,140L371,144L374,144L377,147L380,151L383,147L386,144L389,140L392,140L395,144L398,144L401,151L404,155L407,158L410,158L413,165L416,165L419,169L422,165L425,172L428,165L431,155L434,155L436,140L439,137L442,137L445,137L448,130L451,133L454,140L457,140L460,137L463,144L466,133L469,130L472,130L475,133L478,123L481,116L484,112L487,101L490,101L493,101L496,94L499,98L502,98L505,91L508,87L510,80L513,80L516,84L519,80L522,77L525,77L528,77L531,66L534,70L537,70L540,66L543,66L546,66L549,62L552,59L555,66L558,66L561,70L564,73L567,70L570,62L573,52L576,48L579,52L582,52L584,55L587,59L590,59L593,66L596,66L599,70L602,70L605,66L608,62L611,59L620,20L25,20";
	
//	public String graph_small_metr = "M1,15L1,15L2,25L3,29L4,33L5,36L6,39L7,42L8,45L9,50L9,52L10,60L11,64L12,65L13,66L14,66L15,67L16,67L17,67L18,67L19,67L20,64L21,67L22,67L23,67L24,67L25,67L26,68L26,68L27,67L28,68L29,68L30,67L31,67L32,65L33,66L34,68L35,68L36,66L37,67L38,67L39,68L40,68L41,65L42,64L42,65L43,65L44,65L45,66L46,66L47,65L48,65L49,67L50,67L51,67L52,66L53,67L54,71L55,72L56,69L57,73L58,75L58,79L59,81L60,82L61,79L62,79L63,82L64,84L65,81L66,79L67,80L68,84L69,91L70,94L71,95L72,94L73,96L74,100L75,103L75,102L76,99L77,100L78,100L79,99L80,98L81,97L82,92L83,83L84,76L85,75L86,73L87,78L88,79L89,79L90,79L91,77L91,76L92,73L93,73L94,72L95,73L96,71L97,65L98,59L99,56L100,51L101,50L102,48L103,46L104,49L105,49L106,52L107,52L107,54L108,55L109,51L110,47L111,48L112,48L113,49L114,50L115,49L116,48L117,47L118,47L119,48L120,48L121,50L122,50L123,51L124,51L124,53L125,53L126,54L127,53L128,55L129,53L130,50L131,50L132,47L133,46L134,46L135,46L136,44L137,45L138,47L139,47L140,46L140,48L141,45L142,44L143,44L144,45L145,42L146,40L147,39L148,36L149,36L150,36L151,35L152,36L153,36L154,34L155,33L156,31L156,31L157,32L158,31L159,30L160,30L161,30L162,27L163,28L164,28L165,27L166,27L167,27L168,26L169,25L170,27L171,27L172,28L173,29L173,28L174,26L175,23L176,22L177,23L178,23L179,24L180,25L181,25L182,27L183,27L184,28L185,28L186,27L187,26L188,25L189,15"; 
//	public String prifile_graph_metr = "M25,20L25,20L28,59L31,73L34,87L37,101L40,112L43,123L46,133L49,151L52,162L55,190L58,204L61,211L64,215L67,215L70,218L73,218L76,218L79,218L82,218L85,204L88,218L91,218L94,218L97,218L100,218L103,222L106,222L109,218L111,222L114,222L117,218L120,218L123,211L126,215L129,222L132,222L135,215L138,218L141,218L144,222L147,222L150,211L153,204L156,211L159,208L162,208L165,215L168,215L171,208L174,208L177,218L180,218L183,218L186,215L189,218L192,232L195,236L198,225L201,239L204,247L207,264L210,271L213,275L216,261L219,261L222,275L225,282L228,271L231,264L234,268L237,282L240,307L243,321L246,324L249,321L252,328L255,342L258,353L261,349L264,339L267,342L270,342L273,339L276,335L279,331L281,310L284,278L287,250L290,247L293,239L296,257L299,264L302,264L305,261L308,254L311,250L314,239L317,239L320,236L323,239L326,232L329,208L332,186L335,176L338,158L341,151L344,144L347,137L350,147L353,147L356,162L359,162L362,169L365,172L368,158L371,140L374,144L377,144L380,147L383,151L386,147L389,144L392,140L395,140L398,144L401,144L404,151L407,155L410,158L413,158L416,165L419,165L422,169L425,165L428,172L431,165L434,155L437,155L440,140L443,137L446,137L449,137L451,130L454,133L457,140L460,140L463,137L466,144L469,133L472,130L475,130L478,133L481,123L484,116L487,112L490,101L493,101L496,101L499,94L502,98L505,98L508,91L511,87L514,80L517,80L520,84L523,80L526,77L529,77L532,77L535,66L538,70L541,70L544,66L547,66L550,66L553,62L556,59L559,66L562,66L565,70L568,73L571,70L574,62L577,52L580,48L583,52L586,52L589,55L592,59L595,59L598,66L601,66L604,70L607,70L610,66L613,62L616,59L620,20";
//	public String graph_small_imp = graph_small_metr;
//	public String prifile_graph_imp = prifile_graph_metr;
	public String url_new_dive;
	Random random = new Random(100);
	int draftsCount = 0;
	int divesCount = 0;
	@Test
	public void test_bulk_upload() throws Exception {
		
	//	fb_user_id = createTestFBUser();
	//	loginTempFBUser();
		
		
		register();

		//[13:33:32] Alexander Casassovici: seriously skip it ;)
	//	testFeedbackTool();
		
		checkUrls();
		
		BulkUploadFromComp(); //(Emulator 1 - 1 dive - Using Suunto driver)
		changeUnitSystemToMetric();
		viewDraftInMetric();
		changeUnitSystemToImperial();
		viewDraftInImperial();
		deleteCurrentDive(url_new_dive);
	
		uploadSeveralDives(); // import a profile when creating a new dive when there is more than 1 dive in computer  label=Emulator 2 - 41 dive - Using Mares M2 driver
		
		checkUploadedDives();
		
		makeDivesFromDrafts();
		
		manageAllDives();
		
		logout();
		generalLayoutMainPageNotLoggedin() ;
	
	//	deleteTempFBUser(fb_user_id);
		
		closeBrowser();
	
	}
	

	
	private void makeDivesFromDrafts() throws InterruptedException {
		
		for(int i=1;i<draftsCount/2;i++)
		{	if(random.nextBoolean())
			{
			//switch to drafts
			click("id=draft_count");
			waitForVisible("//div[@id='sb_draftdives']");
			waitForNotVisible("//div[@id='sb_fulldives']");
			Thread.sleep(2000);
		//	sel.mouseDown("//a[contains(@class,'jspArrowUp')]");
			click("//a[contains(@class,'jspArrowUp')]");
			//select a draft
			
			click("//a/div[text()='Draft']");
			waitForVisible("//div[@class='jspPane']/ul/li/a");
			//click first draft
			click("//div[@class='jspPane']/ul/li/a");
			
			waitForNotVisible("id=file_spinning");
		//	waitForVisible("id=country_title");
			
			
			
			if(!isElementPresent("//img[@alt='Private']"))
			{
				System.out.println("draft was not selected! Trying one more time ...");
			//	mouseDown("//a[contains(@class,'jspArrowUp')]");
				click("id=draft_count");
				waitForVisible("//div[@id='sb_draftdives']");
				waitForNotVisible("//div[@id='sb_fulldives']");
				Thread.sleep(1000);
				click("//a[contains(@class,'jspArrowUp')]");
				click("//div/div/div/ul/li/a");
			//	click("//li[@class='scroll_active_item']");
				waitForNotVisible("id=file_spinning");
			}
				
				//if draft was not chosen just breake the for
			if(!getText("css=span.header_title").equals("New Dive" ))
				break;
				
			divesCount++;
			click(editButton); //click edit

			waitForVisible(saveDiveBut);
			
			System.out.println("Adding spot to draft ..."); 
			
			spotSearch(i+"",1);
			Thread.sleep(1000);
			System.out.println("Clicking Save button");
			click(saveDiveBut);
					
			//wait for Dive Editor to close
			waitForNotVisible("id=file_spinning");
		
		//	waitForElement(fbCommFrame4);
	//		waitForVisible("css=label.desc");  //changed from mask
			
			//wait for FB frame to load
	//		waitForVisible("//table[@class='connect_widget_interactive_area']");  
			
			verifyTrue(isElementPresent("//img[@alt='Public']"));
			waitForDiveLink();
			url_new_dive = sel.getLocation();
						
			System.out.println("New Dive with only mandatory info created. " + url_new_dive);
			
		}
		}
		
		System.out.println("Created "+divesCount+" public dives");
	}



	private void manageAllDives() throws InterruptedException {
		
		open(user_url + "/new?bulk=manager");
	//	waitForVisible(saveDiveBut);
		waitForElement("//li[@class='tab_link active']/a[contains(text(),'All Dives')]");
		int Green_locks_count = (sel.getXpathCount("//table[@id='wizard_export_list']//img[@src ='/img/lock_green.png']") ).intValue();
		
		if(Green_locks_count != divesCount)
				fail("Green locks count: "+ sel.getXpathCount("//table[@id='wizard_export_list']//img[@src ='/img/lock_green.png']") +
				" is not equals to dives count " +divesCount);
	
		
		for(int i=2;i<draftsCount+1;i++)
		{	if(random.nextBoolean())
			sel.check("//table[@id='wizard_export_list']/tbody/tr["+i+"]/td/input");
		}
		

		
		
		/* Selenium doesnt work with file upload windows	

		click("id=wizard_export_zxl_valid");
		try {
            
            Robot robot = new Robot(); 
          //  robot.delay(5000);
            sel.windowFocus();
            robot.keyPress(KeyEvent.VK_ENTER);
		} catch (Exception e) {
			e.printStackTrace();}
	
		click("id=wizard_export_udcf_valid");
	
*/
		
		 //set us private
		click("id=wizard_bulk_private_valid");
		
		waitForVisible("link=Select all");
		
		//set as public
		click("link=Select all");
		click("id=wizard_bulk_public_valid");
		 
		
		waitForVisible("link=Select all");
		
		click("link=Select all");
		
		click("id=wizard_bulk_delete_valid");
		
	//	sel.chooseOkOnNextConfirmation();
		assertTrue(sel.getConfirmation().matches("^This will delete the "+draftsCount+" selected dives\\. Are you sure [\\s\\S]$"));
		verifyTrue(isElementPresent("//div[@id='wizard_step_Export']/div"));
		waitForVisible("link=Select all");
	
		
	//	click("id=wizard_close");

		//wait for Dive Editor to close
		for (int second = 0;; second++) {
			if (second >= minute) fail("FAIL: Element id=dialog is still on page " + sel.getLocation());
			try { if (!isElementPresent(saveDiveBut)) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		
		}
		waitForElement("id=draft_count");
	if(getText("id=draft_count").equals("0"))
		System.out.println("All dives deleted");
	else fail("Dive manager didnt delete all dives");

		
	}



	private void checkUploadedDives() throws InterruptedException {
		waitForElement("id=draft_count");
		verifyEquals(draftsCount+"", getText("id=draft_count"));
		System.out.println(draftsCount +" dives uploaded");	
	}



	private void uploadSeveralDives() throws InterruptedException {
		System.out.println("Testing Bulk Mass Upload From Comp");
		open(user_url + "/new?bulk=wizard");
		waitForElement("//li[@class='tab_link active']/a[contains(text(),'Bulk upload')]");
		
		click("id=wizard_import_btn");
		
		waitForElement("wizard_plugin_detect_extract");
		select("id=wizard_computer_select1", "label=Emulator 2 - 41 dive - Using Mares M2 driver");
		
	//	click("id=wizard_plugin_detect_extract");
		
//		click("//input[@id='wizard_plugin_detect_extract']");
		click("//input[@value='Upload dives']");
		
		
		waitForNotVisible("id=progressStatus");	
		waitForVisible("id=dive_list_selected");
		
		sel.removeAllSelections("id=dive_list_selected");
		
		for(int i=0;i<40;i++)
		{	
			if(random.nextBoolean())
			{  draftsCount++;
				sel.addSelection("id=dive_list_selected","value=" + i);
			}
		}
		
			
		click("id=dive_list_selector_button");
		
		//wait for Dive Manager to close
	//	waitForNotVisible("id=dive_list_selector_button");
		waitForDiveLink();	
		waitForVisible("id=main_content_area");
		
	}



	private void checkUrls() throws InterruptedException {
		System.out.println("Checking urls: /new,  /new?bulk=wizard,  /new?bulk=manager..");
		open(user_url + "/new");
		waitForVisible(saveDiveBut);
		waitForElement("//li[@class='tab_link active']/a[contains(text(),'Overview')]");
	
		assertTrue(isVisible("id=wizard-dive-notes"));
		assertEquals(getText("css=#edit_dive_details > p"), "You can fill in these elements manually, or you can import a profile from a computer or a file");
		assertTrue(isElementPresent("//div[@id='edit_dive_details']"));
		assertTrue(isElementPresent("css=ul.token-input-list-facebook"));
		
		open(user_url + "/new?bulk=wizard");
	//	waitForVisible(saveDiveBut);
		waitForElement("//li[@class='tab_link active']/a[contains(text(),'Bulk upload')]");
	
	//	assertEquals(getText("css=a.active_item"), "Bulk Upload");
		assertTrue(isVisible("id=wizard_import_btn"));
		assertTrue(isVisible("id=wizard_upload_btn"));
		assertEquals(getText("css=span.header_title"), "Dive manager");
		//assertEquals(getText("//div[@id='wizard_add_profile']/p[3]"), "Currently supported file format for import :");
		assertEquals(getText("//div[@id='wizard_add_profile']/p[3]"), "If you already have a lot of dives logged in another software, and want to import all these data quickly and easily in Diveboard, check out the Bulk uploader.");
		
		assertEquals(getText("css=i"), "If the software from your favorite dive computer cannot export the data to one of these format, you can use the Panic! button to contact us, and we'll see what we can do !");
		
		
		//	click("id=wizard_close");
	//	waitForVisible("css=img.showhome");
	//	assertFalse(isVisible(saveDiveBut));
		
		open(user_url + "/new?bulk=manager");
	//	waitForVisible(saveDiveBut);
		waitForElement("//li[@class='tab_link active']/a[contains(text(),'All Dives')]");
	//	waitForElement("css=a.active_item");
	//	assertEquals(getText("css=a.active_item"), "Dive Manager");
		assertEquals(getText("css=span.header_title"), "Dive manager");
		assertEquals(getText("css=label"), "Manage all your dives with a single click !");
		assertTrue(isVisible("link=Select all"));
		
		assertTrue(isVisible("id=wizard_export_udcf_valid"));
		assertTrue(isVisible("id=wizard_bulk_public_valid"));
		assertTrue(isVisible("id=wizard_bulk_private_valid"));
		assertTrue(isVisible("id=wizard_bulk_delete_valid"));
			
		
	//	click("id=wizard_close");
		//waitForVisible("css=img.showhome");
		//assertFalse(isVisible(saveDiveBut));
		
	}



	private void testFeedbackTool() throws InterruptedException {
		System.out.println("Testing Feedback Tool..");
		click(panicButton);
		
				
		waitForVisible("css=section.main > div.scrollbarPaper");
        waitForVisible("id=contact_subject");
        
        Thread.sleep(1000);
        click("id=contact_subject");
        sel.type("id=contact_subject", "");
		sel.typeKeys("id=contact_subject", "Testing feedback tool");
		
		
		click("name=ticket[message]");
        sel.type("name=ticket[message]", "");
		sel.typeKeys("name=ticket[message]", "Hello from autotest bot!");
		Thread.sleep(1000);
	//	verifyEquals("on", sel.getValue("name=screenshot"));
	//clickk("name=email");
   //     sel.type("name=email", "");
		sel.type("name=email", randomTestUsername +"@diveboard.co");
		sel.typeKeys("name=email", "m");
		sel.mouseDown("css=section.main > div.scrollbarPaper");
		
	//	waitForVisible("class='uvFieldEtc uvFieldEtc-reset'");
		
		Thread.sleep(1000);
		
		//click Send button
		click("css=button.uvStyle-button");
		Thread.sleep(1000);
		click("name=email");
		waitForVisible("name=display_name");
		click("name=display_name");
        sel.type("name=display_name", "");
		sel.typeKeys("name=display_name", randomTestUsername );
		Thread.sleep(1000);
		
		//click Send button
		click("css=button.uvStyle-button");
		
		waitForVisible("link=Send another message");
		
				//close panic popup
		click("css=button");
		
			
		
		}



	public void BulkUploadFromComp() throws InterruptedException	{ 
		
		System.out.println("Testing Bulk Upload From Comp");
		//click "Bulk Upload from comp..."
		if(isElementPresent("css=img.sidebar_upload.tooltiped"))
		{
			click("css=img.sidebar_upload.tooltiped");
			waitForElement("//li[@class='tab_link active']/a[contains(text(),'Bulk upload')]");
			
					
			
		
			click("id=wizard_import_btn");
		waitForVisible("id=wizard_plugin_detect_extract");
			
						
		System.out.println("Selecting Emulator 1 ");
			
			verifyTrue(getText("css=#detectBox1 > p").equals("Select your computer's type in the list below")	);
					
					//	sel.select("id=wizard_computer_select1", "label=Emulator 1 - 1 dive - Using Suunto driver");
						
			click("css=option[value='Emu Suunto']");
			Thread.sleep(1000);
		//	click("//input[@id='wizard_plugin_detect_extract']");// id=wizard_plugin_detect_extract
				//		waitForElement("css=option[value=0]");
			//			Thread.sleep(1000);
					//	click("//input[@value='Upload dives']");
					
			click("//div[@id='detectBox1']/p[2]/input");
			
						waitForNotVisible("id=progressStatus");					
			
			
			
		
			waitForVisible("id=dive_list_selector_button");
			click("id=dive_list_selector_button");
			
			Thread.sleep(1000);
			waitForVisible("id=main_content_area");
			waitForVisible("//div[@class='jspPane']/ul/li/a");
			
			System.out.println("Single dive(Emulator 1 - 1 dive - Using Suunto driver) from dive computer was uploaded");
		
			
			
		} else fail("Could not upload from dive comp!"); 
		
		url_new_dive = url + sel.getAttribute("//div[@class='jspPane']/ul/li/a@href");
		
		System.out.println("Draft's url " +url_new_dive);
	}

	private void viewDraftInMetric() throws InterruptedException {
	//	click("//a[@id='user_dives_url']/span/img[2]"); 
	//	waitForVisible("css=div.double_box.places_dived");
	//	click("//div[@id='sidebar_manager_container']//div[@class='jspPane']//a"); //open last draft
		//wait for draft to appear
	open(url_new_dive);
		
	waitForElement("id=main_content_area");
	
	
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not open draft");
			//css=span.header_title
			try {if (getText("css=span.header_title").equals("New Dive"))break; 
				}catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		}
		
		
		
		//overview
		verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[2]").equalsIgnoreCase("Max Depth: 28.7m Duration:66mins"));
		
		verifyTrue(getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("Temp: Surf 20") 
				&&
				getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("C Bottom 20"));
		
		
	
	//	Thread.sleep(1000);
		
		
		
		 
	//	 verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf(\"" + graph_small + "\") > 0"));
		
		 /*
		 String innerhtml = sel.getEval("window.document.getElementById(\"graph_small\").innerHTML");
			boolean match = (innerhtml.contains(graph_small_metr)) ? true : false;
			verifyEquals("true",""+match);
	 	*/
		 viewDraft();
	 	//profile
	 	
	 //	 Thread.sleep(2000);				 
	 //	 System.out.println("Verifying profile graph..");
	 
	 //	 verifyEquals("true", sel.getEval("window.document.getElementById(\"graphs\").innerHTML.indexOf(\"" + prifile_graph + "\") > 0"));	 
	 	/*
	 	innerhtml = sel.getEval("window.document.getElementById(\"graphs\").innerHTML");
		 match = (innerhtml.contains(prifile_graph_metr)) ? true : false;
		verifyEquals("true",""+match);
		*/
	 	 
	 	 
	 	 System.out.println("Test draft view in Metric inspection finished ");
 	
	
			
	}
	
	private void viewDraftInImperial() throws InterruptedException {
	//	click("//div[@class='jspPane']");
	//	sel.refresh(); // without refresf metric info is shown
	//	sel.waitForPageToLoad("300000");
		//wait for draft to appear
	//	click("//a[@id='user_dives_url']/span/img[2]"); 
	//	waitForVisible("css=div.double_box.places_dived");
	//	click("//div[@id='sidebar_manager_container']//div[@class='jspPane']//a"); //open last draft
		open(url_new_dive);
		waitForElement("id=main_content_area");
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not open draft");
			//css=span.header_title
			try { if (getText("css=span.header_title").equals("New Dive")) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		}

		//overview
		
		verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[2]").equalsIgnoreCase( "Max Depth: 94ft Duration:66mins"));
			
		
		verifyTrue(getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("Temp: Surf 68") 
				&&
				getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]").
				contains("F Bottom 68"));
		
		
		
			//	Thread.sleep(2000);
	//	 System.out.println("Verifying small graph..");
		
		
		 viewDraft();
	 	//profile
		
		System.out.println("Test draft view inspection in Imperial finished");
		 			
			 
	}
	
	private void viewDraft() throws InterruptedException
	{	 // * album of all pictures/videos on "pictures" tab not exists
		 verifyFalse(isElementPresent("tab_pictures_link")); 
		
		waitForVisible("graph_small");
		Thread.sleep(1000);
	 	System.out.println("Verifying small graph..");
	
//		String innerhtml = sel.getEval("window.document.getElementById(\"graph_small\").innerHTML");
	//	boolean match = (innerhtml.contains(graph_small)) ? true : false;
	//	verifyEquals("true",""+match);
		
	
	 	verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf(\"" + graph_small + "\") > 0"));
		
	 	verifyTrue(getText("//div[@id='tab_overview']/div[1]/ul/li[1]").equalsIgnoreCase("Date: 2010-07-31 - 14:34"));

		//Now If there are no notes, there should not be the diver's notes frame
		//verifyEquals(getText("css=div.divers_comments"), "Diver's Notes No notes for this dive!");
		verifyFalse(isElementPresent("css=div.divers_comments"));
		
		verifyEquals(getText("css=span.header_title"), "New Dive");
		
	//	verifyTrue(sel.isTextPresent("New Dive"));
		verifyEquals(getText("//div[@id='main_content_area']//li[2]"), " ");
		
		
		verifyEquals(getText("css=div.triple_box > p"), "No pictures for this dive");
		verifyTrue(getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[3]").equalsIgnoreCase("Species spotted: No species spotted"));
		
		verifyTrue (isElementPresent("//img[@alt='Private']"));
		 Thread.sleep(1000);
 			
	 	// GO TO PROFILe tab
	 	//	clickAt("tab_profile_link","0,0");
	 		click(tab_profile);
	 	 	
	 		waitForVisible("//div[@id='tab_profile']/h1");
	 
	 		 		waitForVisible("graphs");
	 		 		 Thread.sleep(1000);
	 				 System.out.println("Verifying profile graph..");
	 				verifyEquals("true", sel.getEval("window.document.getElementById(\"graphs\").innerHTML.indexOf(\"" + prifile_graph + "\") > 0"));
	 				 		 
	}
	
	protected void generalLayoutMainPageNotLoggedin() {
		System.out.println("Checking general layout for not logged in user main page..");
				
		verifyTrue(isElementPresent("css=img[alt=Features]"));
		verifyEquals(getText("css=p"),"Diveboard lets you dive into the marvels of scuba diving. Whether you're an occasional diver or a pro, discover new destinations, share your passion and help monitor the ecosystem.");
		verifyTrue(isElementPresent("css=li.selected > img"));
		verifyTrue(isElementPresent("new_index_left_btn"));
		verifyTrue(isElementPresent("new_index_right_btn"));
		verifyTrue(isElementPresent("css=img[alt=explore]"));
		verifyTrue(isElementPresent("new_bottom_signin"));
		verifyTrue(isElementPresent("new_top_signin_box"));
		verifyEquals(getText("css=div.new_bottom_feat > p"), "Keep your dive memories in Diveboard's online logbook. Select the spots you've dived, add the species you've encountered, your dive details and even pics or videos and your memories will be saved on the cloud.");
		//	verifyTrue(sel.isTextPresent("Keep your dive memories in Diveboard's online logbook. Select the spots you've dived, add the species you've encountered, your dive details and even pics or videos and your memories will be saved on the cloud."));
		verifyTrue(isElementPresent("//div[@id='new_bottom_feats_area']/div[3]/img"));
		//verifyTrue(sel.isTextPresent("There's certainly the spot you just dived in our evergrowing spot database. Explore the interactive map and select your next destinations based on diver's feedbacks."));
		
		verifyEquals(getText("//div[@id='new_bottom_feats_area']/div[3]/p"), "There's certainly the spot you just dived in our evergrowing spot database. Explore the interactive map and select your next destinations based on diver's feedbacks.");
	//	verifyTrue(isElementPresent("css=div.new_bottom_feat &gt; img[alt=#]"));
		
		verifyTrue(isElementPresent("//div[@id='new_bottom_feats_area']/div[5]/img"));
		verifyTrue(isElementPresent("//div[@id='new_bottom_feats_area']/div[6]/img"));
		verifyEquals(getText("//div[@id='new_bottom_feats_area']/div[6]/p"), "Publish your dives and share your experiences on social networks and with your friends. Native Facebook integration, commenting and likes included!");
	//	verifyTrue(sel.isTextPresent("Publish your dives and share your experiences on social networks and with your friends. Native Facebook integration, commenting and likes included!"));
		
		
		verifyTrue(isElementPresent("//div[@id='new_bottom_feats_area']/div[8]/img"));
		verifyTrue(isElementPresent("id=Panic_mg"));
		verifyEquals(getText("//div[@id='new_bottom_feats_area']/div[8]/p"), "Thanks to our Mac/PC/Linux navigator plugin, connect directly to your dive computer and upload your dive profiles straight to your Diveboard logbook.");
		verifyEquals(getText("//div[@id='new_bottom_feats_area']/div[5]/p"), "Through EOL, Obis and GBIF we built a tremendous database of marine species. Wanna see seahorses ? Wondering what that weird fish you saw during your last dive was ? We can help you out !");
		//	verifyTrue(sel.isTextPresent("Through EOL, Obis and GBIF we built a tremendous database of marine species. Wanna see seahorses ? Wondering what that weird fish you saw during your last dive was ? We can help you out !"));
		verifyTrue(isElementPresent("//div[@id='new_bottom_feats_area']/div[10]/img"));
		verifyEquals(getText("//div[@id='new_bottom_feats_area']/div[10]/p"), "Easily add pictures and videos stored in popular photo/video-sharing services to your logbook and make your memories even more vivid !");
		verifyTrue(isElementPresent("//div[@id='new_bottom_feats_area']/div[11]/img"));
		verifyEquals(getText("//div[@id='new_bottom_feats_area']/div[11]/p"), "By uploading your dive profiles and filling up the DAN questionnaire, help make diving safer. By marking down the species you encountered, help scientists get a real-time view of the evolution of the marine ecosystem.");
		verifyTrue(isElementPresent("new_bottom_blog_box"));
		verifyTrue(isElementPresent("css=img.blog_see_more"));
		verifyTrue(isElementPresent("css=a.new_bottom_blog_title"));
		
		verifyNotEquals(getText("css=li > p"), "... Read More!");
		
		verifyEquals(getText("css=li > p > a"), "Read More!");
		verifyTrue(isElementPresent("//div[@id='new_bottom_blog_box']/ul[2]/li[2]/a"));
	//	verifyTrue(isElementPresent("css=ul.new_bottom_blog_text > li:nth(1) > p"));
	//	verifyTrue(isElementPresent("css=ul.new_bottom_blog_text > li:nth(1) > p > a"));
		
		verifyTrue(getText("//div[@id='footer_container']/div/ul/li[2]/strong").equalsIgnoreCase( "Number of Dives:"));

		verifyTrue(isElementPresent("css=div.footer_one > ul > li"));	
		verifyTrue(isElementPresent("css=div.name_block"));	
		verifyEquals(getText("css=div.footer_two > ul > li > strong"), "COMMUNITY AND HELP");
	//	verifyTrue(sel.isTextPresent("Community and help"));	
		verifyEquals(getText("css=div.footer_three > ul > li > strong"), "ABOUT DIVEBOARD");
	//	verifyTrue(sel.isTextPresent("About Diveboard"));	
		
	//	System.out.println("Checking general layout for not logged in user main page finished");
		
	
	}	
}
