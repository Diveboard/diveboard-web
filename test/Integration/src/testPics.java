

import org.junit.Test;

import diveboard.CommonActions;

public class testPics  extends CommonActions {

	public String url_new_dive;
	public String test_note = "a test note for this \"√©m√©rite\" dive at l'√©chelle, near the village of ÂªÉÊùëÁôΩÂ≤©- \n<a> wonderful dive </a>; with me & everyone !";
	
	public String graph_small_metr = "M32,20C32,20,36,40,37,42C38,45,41,57,42,59C43,61,45,72,47,74C49,76,50,75,52,75C54,75,55,75,57,75C59,75,59,76,62,76C64,76,64,76,67,76C69,76,69,76,72,76C74,76,74,77,77,76C79,76,79,74,81,74C84,74,84,74,86,75C88,76,90,79,91,81C92,83,94,88,96,90C98,92,99,90,101,92C103,94,105,102,106,104C107,106,109,111,111,112C113,113,114,110,116,109C118,108,119,108,121,106C122,104,124,89,126,87C127,85,129,86,131,84C133,83,134,83,135,81C136,79,138,59,140,58C142,57,143,62,145,62C148,62,148,59,150,58C152,57,153,56,155,56C157,56,158,57,160,58C162,59,163,60,165,61C167,62,168,63,170,62C172,61,172,53,175,52C177,51,177,54,180,54C182,54,182,52,184,51C186,49,187,47,189,45C191,43,192,42,194,41C196,39,197,39,199,38C201,37,202,37,204,36C206,35,207,33,209,33C211,33,212,36,214,35C216,34,216,30,219,30C221,30,221,35,224,34C226,33,229,20,229,20";
	public String graph_small_imp = "M32,20C32,20,36,41,37,43C38,46,41,58,42,60C43,62,45,74,47,76C49,78,50,77,52,77C54,77,55,77,57,77C59,77,59,78,62,78C64,78,64,78,67,78C69,78,69,78,72,78C74,78,74,79,77,78C79,78,79,76,81,76C84,76,84,76,86,77C88,78,90,81,91,83C92,85,94,91,96,93C98,95,99,93,101,95C103,97,105,105,106,107C107,109,109,114,111,115C113,116,114,113,116,112C118,111,119,111,121,109C122,107,124,92,126,90C127,88,129,89,131,87C133,86,134,85,135,83C136,81,138,60,140,59C142,58,143,64,145,64C148,64,148,60,150,59C152,58,153,58,155,58C157,58,158,58,160,59C162,60,163,62,165,63C167,64,168,65,170,64C172,63,173,55,175,54C177,53,177,56,180,56C182,56,182,54,184,53C186,51,187,48,189,46C191,44,192,43,194,42C196,40,197,39,199,38C201,37,202,37,204,36C206,35,207,33,209,33C211,33,212,36,214,35C216,34,216,30,219,30C221,30,221,35,224,34C226,33,229,20,229,20";
	public String prifile_graph_metr = "M31,20C31,20,33,20,34,20C35,21,37,47,37,48C37,50,40,57,40,58C40,60,43,67,43,68C43,70,46,77,46,78C47,80,49,85,49,86C50,88,52,92,52,93C53,95,55,101,55,102C55,104,58,113,58,114C59,116,61,121,61,122C61,124,64,141,64,142C64,144,66,151,67,152C68,154,69,156,70,157C71,158,72,160,73,160C75,161,75,160,76,160C78,161,78,163,79,163C81,164,81,163,82,163C84,163,84,163,85,163C87,163,87,163,88,163C90,163,90,164,91,163C92,162,93,152,94,152C96,152,96,162,97,163C98,164,99,163,100,163C102,163,102,163,103,163C105,163,105,163,106,163C108,163,108,162,109,163C110,164,111,164,112,165C113,166,114,165,115,165C116,164,117,163,118,163C120,163,120,164,121,165C122,166,123,166,124,165C125,164,126,164,127,163C128,162,129,164,130,163C131,162,132,157,133,157C134,157,135,159,136,160C137,161,138,164,139,165C140,166,141,166,142,165C143,164,143,160,145,160C146,160,147,163,148,163C149,163,150,162,151,163C152,164,153,164,154,165C155,165,156,166,157,165C158,164,159,158,160,157C161,156,161,152,163,152C164,152,164,157,166,157C167,157,167,156,169,155C170,155,171,154,172,155C173,156,174,159,175,160C176,161,177,161,178,160C179,159,180,156,181,155C182,154,183,154,184,155C185,156,186,162,187,163C188,164,188,163,190,163C191,163,191,164,193,163C194,163,194,160,196,160C197,160,198,162,199,163C200,164,201,171,202,172C203,173,203,175,205,175C206,175,206,167,208,167C209,167,210,175,211,177C211,178,213,180,214,182C215,183,216,193,217,195C217,196,219,199,220,200C221,201,221,203,223,202C224,202,225,193,226,192C227,191,228,191,229,192C230,193,231,201,231,202C232,204,233,208,234,208C236,208,236,201,237,200C238,198,239,195,240,195C242,195,242,196,243,197C244,198,246,207,246,208C246,210,249,225,249,226C249,228,251,235,252,236C253,237,254,238,255,238C257,238,257,236,258,236C260,236,260,240,261,241C262,243,264,250,264,251C265,253,266,259,267,259C269,259,269,257,270,256C271,255,272,248,273,248C275,248,275,251,276,251C278,252,278,251,279,251C281,250,281,249,282,248C283,247,284,247,285,246C286,245,287,244,288,243C289,242,291,229,291,228C291,226,294,207,294,206C294,204,296,186,297,185C298,184,299,183,300,182C301,181,302,177,303,177C305,177,305,189,306,190C307,191,308,194,309,195C310,196,311,195,312,195C313,194,314,193,315,192C316,191,317,189,318,188C319,187,320,186,321,185C322,184,323,178,324,177C325,176,326,178,327,177C328,176,329,175,330,175C331,175,332,177,333,177C334,177,336,173,336,172C336,171,339,156,339,155C339,154,342,140,342,139C342,138,345,133,345,132C345,131,347,120,348,119C349,118,350,115,351,114C352,113,353,110,354,109C355,108,355,104,357,104C358,104,359,111,360,112C361,113,362,111,363,112C364,113,365,121,366,122C367,123,368,121,369,122C370,123,371,126,372,127C373,128,373,130,375,129C376,129,378,121,378,119C378,118,379,108,381,107C382,107,382,108,384,109C385,109,385,108,387,109C388,109,389,111,390,112C391,113,391,114,393,114C394,114,395,113,396,112C397,111,398,110,399,109C400,108,400,108,402,107C403,107,403,106,405,107C406,108,406,108,408,109C409,109,410,108,411,109C412,110,413,113,414,114C415,115,416,116,417,117C418,118,418,118,420,119C421,119,422,118,423,119C424,120,424,123,426,124C427,125,427,123,429,124C430,124,430,127,431,127C433,127,433,124,434,124C436,124,436,129,437,129C439,129,439,125,440,124C441,122,442,118,443,117C444,116,445,118,446,117C447,116,448,108,449,107C450,106,451,104,452,104C454,103,454,104,455,104C457,104,457,105,458,104C459,103,460,98,461,98C463,98,463,101,464,102C465,103,466,106,467,107C468,108,469,107,470,107C472,107,472,104,473,104C475,104,475,109,476,109C478,109,478,103,479,102C480,101,481,99,482,98C483,97,484,98,485,98C486,99,487,102,488,102C490,102,490,94,491,93C492,92,493,89,494,88C495,87,496,87,497,86C498,85,499,79,500,78C501,77,502,78,503,78C505,78,505,79,506,78C507,77,508,73,509,73C511,73,511,76,512,76C513,77,514,77,515,76C516,75,517,72,518,71C519,70,520,69,521,68C522,67,523,64,524,63C525,62,526,63,527,63C528,63,529,66,530,66C531,66,532,64,533,63C534,62,535,62,536,61C537,60,537,61,539,61C540,61,541,62,542,61C543,60,544,53,545,53C546,53,547,56,548,56C549,56,550,57,551,56C552,56,553,53,554,53C555,53,555,53,557,53C558,53,559,54,560,53C561,52,562,52,563,51C564,50,564,48,566,48C567,48,568,52,569,53C570,54,570,52,572,53C573,53,574,55,575,56C576,57,576,58,578,58C579,58,580,57,581,56C582,55,583,52,584,51C585,50,586,44,587,43C588,42,588,40,590,40C591,40,591,43,593,43C594,43,594,42,596,43C597,44,598,44,599,45C600,46,600,47,602,48C603,49,604,47,605,48C606,49,607,52,608,53C609,54,609,52,611,53C612,53,612,55,614,56C615,56,615,57,617,56C618,56,619,54,620,53C621,52,622,52,623,51C624,50,625,50,626,48C627,47,629,20,629,20";
	public String prifile_graph_imp = "M31,20C31,20,33,20,34,20C35,21,37,48,37,49C37,51,40,59,40,60C40,62,43,69,43,70C43,72,46,80,46,81C47,83,49,87,49,88C50,90,52,95,52,96C53,98,55,104,55,105C55,107,58,117,58,118C59,120,61,124,61,125C61,127,64,145,64,146C64,148,67,155,67,156C68,158,69,161,70,162C71,163,72,164,73,165C75,166,75,165,76,165C78,166,78,168,79,168C81,169,81,168,82,168C84,168,84,168,85,168C87,168,87,168,88,168C90,168,90,169,91,168C92,167,93,156,94,156C96,156,96,167,97,168C98,169,99,168,100,168C102,168,102,168,103,168C105,168,105,168,106,168C108,168,108,167,109,168C110,169,111,169,112,170C113,171,114,171,115,170C116,169,117,168,118,168C120,168,120,169,121,170C122,171,123,171,124,170C125,169,126,169,127,168C128,167,129,169,130,168C131,167,132,162,133,162C134,162,135,164,136,165C137,166,138,169,139,170C140,171,141,171,142,170C143,169,143,165,145,165C146,165,147,168,148,168C149,168,150,167,151,168C152,169,153,169,154,170C155,171,156,171,157,170C158,169,159,163,160,162C161,161,161,156,163,156C164,156,164,162,166,162C167,162,168,161,169,160C170,159,171,159,172,160C173,161,174,164,175,165C176,166,177,166,178,165C179,164,180,161,181,160C182,159,183,159,184,160C185,161,186,167,187,168C188,169,188,168,190,168C191,168,191,169,193,168C194,168,194,165,196,165C197,165,198,167,199,168C200,169,201,177,202,178C203,179,203,181,205,181C206,181,206,173,208,173C209,173,210,181,211,183C211,184,213,186,214,188C215,189,216,199,217,201C217,202,219,206,220,207C221,208,221,210,223,209C224,209,225,200,226,199C227,198,228,198,229,199C230,200,231,208,231,209C232,211,233,215,234,215C236,215,236,208,237,207C238,205,239,201,240,201C242,201,242,203,243,204C244,205,246,214,246,215C246,217,249,232,249,233C249,235,251,243,252,244C253,245,254,246,255,246C257,246,257,244,258,244C260,244,261,248,261,249C262,251,264,258,264,259C264,261,266,268,267,268C269,268,269,265,270,264C271,263,272,257,273,257C275,257,275,258,276,259C278,260,278,259,279,259C281,258,281,258,282,257C283,256,284,255,285,254C286,253,287,252,288,251C289,250,291,237,291,236C291,234,294,214,294,213C294,211,296,192,297,191C298,190,299,189,300,188C301,187,302,183,303,183C305,183,305,195,306,196C307,197,308,200,309,201C310,202,311,202,312,201C313,200,314,200,315,199C316,198,317,194,318,193C319,192,320,192,321,191C322,190,323,184,324,183C325,182,326,184,327,183C328,182,329,181,330,181C331,181,332,183,333,183C334,183,335,179,336,178C336,177,339,161,339,160C339,159,342,144,342,143C342,142,345,137,345,136C345,135,347,124,348,123C349,122,350,119,351,118C352,117,353,113,354,112C355,111,355,107,357,107C358,107,359,114,360,115C361,116,362,114,363,115C364,116,365,124,366,125C367,126,368,124,369,125C370,126,371,130,372,131C373,132,373,134,375,133C376,133,378,125,378,123C378,122,379,110,381,110C382,110,382,111,384,112C385,112,385,111,387,112C388,112,389,114,390,115C391,116,391,118,393,118C394,118,395,116,396,115C397,114,398,113,399,112C400,111,400,111,402,110C403,110,403,109,405,110C406,111,406,111,408,112C409,112,410,111,411,112C412,113,413,117,414,118C415,119,416,119,417,120C418,121,418,123,420,123C421,123,422,122,423,123C424,124,424,127,426,128C427,129,427,127,429,128C430,128,430,131,431,131C433,131,433,128,434,128C436,128,436,133,437,133C439,133,439,129,440,128C441,126,442,121,443,120C444,119,445,121,446,120C447,119,448,111,449,110C450,109,451,107,452,107C454,106,454,107,455,107C457,107,457,108,458,107C459,106,460,101,461,101C463,101,463,104,464,105C465,106,466,109,467,110C468,111,469,110,470,110C472,109,472,107,473,107C475,107,475,112,476,112C478,112,478,106,479,105C480,104,481,102,482,101C483,100,484,100,485,101C486,102,487,105,488,105C490,105,490,97,491,96C492,95,493,92,494,91C495,90,496,89,497,88C498,87,499,82,500,81C501,80,502,81,503,81C505,81,505,82,506,81C507,80,508,75,509,75C511,75,511,77,512,78C513,79,514,79,515,78C516,77,517,74,518,73C519,72,520,71,521,70C522,69,523,66,524,65C525,64,526,65,527,65C528,65,529,67,530,67C531,67,532,66,533,65C534,64,535,62,536,62C537,62,537,62,539,62C540,62,541,63,542,62C543,61,544,54,545,54C546,54,547,56,548,57C549,58,550,58,551,57C552,56,553,54,554,54C555,54,555,54,557,54C558,54,559,55,560,54C561,53,562,53,563,52C564,51,564,49,566,49C567,49,568,53,569,54C570,55,570,53,572,54C573,54,574,56,575,57C576,58,576,60,578,60C579,60,580,58,581,57C582,56,583,53,584,52C585,51,586,44,587,43C588,42,588,41,590,41C591,41,591,42,593,43C594,43,594,42,596,43C597,43,598,45,599,46C600,47,601,48,602,49C603,50,604,48,605,49C606,50,607,53,608,54C609,55,609,53,611,54C612,54,612,56,614,57C615,57,615,58,617,57C618,56,619,55,620,54C621,53,622,53,623,52C624,51,625,51,626,49C627,48,629,20,629,20";
	
	public String fav_pic_local_addr;
	
	@Test
	public void test_CreateFullNewDive() throws Exception {
		
		fb_user_id =	createTestFBUser();
		loginTempFBUser();
		
		createFullNewDive();
	//	changeUnitSystemToMetric();
		viewDiveInMetric();
	//	changeUnitSystemToImperial();
	//	viewDiveInImperial();
		
		deleteCurrentDive(url_new_dive);
		deleteTempFBUser(fb_user_id);
		
	}

	


	public void viewDiveInImperial() throws Exception {
		System.out.println("View dive in Imperial");
		sel.open(url_new_dive);
		//* Dive information displayed on main page : date, time, depth, duration, temperatures, notes, fishes [if available - if not then correctly displayed]
	
		
		verifyEquals(sel.getText("//div[@id='tab_overview']/div[1]/ul/li[2]"), "Max Depth: 94.2ft Duration:66mins");
		verifyEquals(sel.getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]"), "Temp: Surf 91∞F Bottom 66∞F");
		
	// graphs	
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf(\"" + graph_small_imp + "\") > 0"));
		viewDive();
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graphs\").innerHTML.indexOf(\"" + prifile_graph_imp + "\") > 0"));

	System.out.println("Dive in Imperial checked");
	}


	private void viewDiveInMetric()  throws Exception {
		System.out.println("View dive in Metric");	
		
		sel.open(url_new_dive);
		verifyEquals(sel.getText("//div[@id='tab_overview']/div[1]/ul/li[2]"), "Max Depth: 28.7m Duration:66mins");
	
		verifyEquals(sel.getText("//div[@id='tab_overview']/div[2]/div[3]/ul/li[2]"), "Temp: Surf 33∞C Bottom 19∞C");
		
			
		
		verifyEquals("true", sel.getEval("window.document.getElementById(\"graph_small\").innerHTML.indexOf(\"" + graph_small_metr + "\") > 0"));
			viewDive();
			verifyEquals("true", sel.getEval("window.document.getElementById(\"graphs\").innerHTML.indexOf(\"" + prifile_graph_metr + "\") > 0"));
			System.out.println("Dive in Metric checked");	
				
	}
		

private void viewDive() throws InterruptedException{
	verifyEquals(sel.getText("//div[@id='tab_overview']/div[1]/ul/li[1]"), "Date: 2010-07-31 - 14:34");

	verifyEquals(sel.getText("css=div.divers_comments"), "Diver's Notes "+test_note);
	
	//	verifyTrue(sel.isTextPresent(test_note));  css=div.divers_comments
	//	verifyEquals("Dive type : recreational, traaining, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5", 
		//				sel.getText("css=div.triple_box > ul > li"));
		
	//	verifyTrue(sel.isTextPresent("Dive type : recreational, training, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5"));
		verifyEquals("Dive type : recreational, training, night dive, deep dive, drift, wreck, cave, reef, photo, research, test1, test2, test3, test4, test5", sel.getText("css=div.triple_box > ul > li"));
		verifyTrue(sel.isElementPresent("//div[@id='tab_overview']/div[3]/div[1]/ul/li[1]/a/img")); 
		verifyTrue(sel.isElementPresent("//div[@id='tab_overview']/div[3]/div[2]/ul/li[1]/a/img"));
		verifyEquals("Blue Hole", sel.getText("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span"));
		verifyEquals("Malta", sel.getText("country_title"));
		verifyEquals("Gozo", sel.getText("link=Gozo"));
		verifyEquals("Mediterranean Sea", sel.getText("link=Mediterranean Sea"));
		verifyEquals("Species spotted:", sel.getText("css=div.triple_box > ul > li:nth(2) > strong"));
		verifyEquals("Gulf grouper", sel.getText("link=Gulf grouper"));
	//	verifyFalse(sel.isTextPresent("dolphin"));
		verifyTrue(sel.isElementPresent("featured_pic"));
		verifyTrue(sel.isElementPresent("//img[@id='featured_pic'][contains(@src ,'IMG_4564.JPG')]"));
		verifyTrue(sel.isVisible("//div[@id='graph_small']/div"));
		
	// * Preferred picture on main dive page
	////div[2]/div/div/div/div/a/img[contains(@src, '/user_images/image-cache-160_m.jpg')]
		verifyTrue(sel.isElementPresent("//div[2]/div/div/div/div/a/img[contains(@src, '"+fav_pic_local_addr+"')]"));
		//map
		
		sel.click("css=div.triple_box_content > a > img");
		waitForElement("tab_gmap_holder");
		verifyTrue(sel.isElementPresent("css=div[title=Drag to zoom] > img"));  // zoom is available
		verifyTrue(sel.isElementPresent("//a[@id='tab_map_link' and @class = 'active']")); //map tab is active
		
//	isElementPresent["//div[@id='galleria']/div/div[1]/div[1]//img[contains(@src, '/user_images/image-cache-154_m.jpg')]");	
		
		//pictures
		sel.click("tab_pictures_link");
		
		waitForVisible("//div[@id='galleria']/div/div[1]/div[1]/div[2]/img");
		waitForVisible("css=div.galleria-thumbnails-list");

		verifyTrue(sel.isElementPresent("//div[@id='galleria']/div/div[2]/div[2]/div/div[1]/img"));
		verifyTrue(sel.isElementPresent("//div[@id='galleria']/div/div[2]/div[2]/div/div[2]/img"));
		verifyTrue(sel.isElementPresent("//div[@id='galleria']/div/div[2]/div[2]/div/div[3]/img"));
		
	//	int num_of_Pict = (Integer) sel.getCssCount("//div[@class='galleria-image']");
		int num_of_Pict = (Integer) sel.getCssCount("css=div.galleria-image > img");
		System.out.println("Number of uploaded pictures = " + (num_of_Pict-1));
		
		for(int i=1; i<num_of_Pict; i++)
		{
		//check first pic //div[@id='galleria']/div/div[2]/div[2]/div/div/img
		String local_address = sel.getAttribute("//div[@id='galleria']/div/div[2]/div[2]/div/div["+i+"]/img@src");
		
		waitForElement("//div[@id='galleria']/div/div[1]/div[1]//img[contains(@src, '"+local_address+"')]");
		System.out.println(i + " picture checked");
	
		
		sel.click("//div[@id='galleria']/div/div[1]/div[4]/div[1]");
		}
		

//profile
		sel.click("tab_profile_link");
		
		
		
	}

	private void createFullNewDive() throws InterruptedException {
		sel.open("/");
		sel.click("create_dive_2");
		System.out.println("new dive creating..."); 
		//LOCATION
		
		waitForVisible("wizard_menu");

	
		
		waitForElement("spotsearch");
		// * searching for a spot
		System.out.println("Location.."); 
		
		sel.type("spotsearch", "");
		sel.typeKeys("spotsearch", "blu ho go");
		
		for (int second = 0;second <= minute; second++) {
			if (second == 15) 
			{
				System.out.println("location was not filled in. trying one more time..."); 
				sel.type("spotsearch", "");
				sel.typeKeys("spotsearch", "blu ho go");
				
			}
				
			try { if (sel.isElementPresent("//ul[2]/li[2]/a")) break; } catch (Exception e) {}
			Thread.sleep(1000);
		}
		
		
		
		for (int second = 0;; second++) {
			if (second >= minute) fail("Could not find dd 'Blue Hole, Gozo, Mediterranean Sea, Malta' ");
			try { 
				if (sel.getText("//ul[2]/li[2]/a").equals("Blue Hole, Gozo, Mediterranean Sea, Malta")) 
					break; } catch (Exception e) {}
			Thread.sleep(1000);
		}

		sel.mouseOver("//html/body/ul/li/a[.='Blue Hole, Gozo, Mediterranean Sea, Malta']");
		sel.click("//html/body/ul/li/a[.='Blue Hole, Gozo, Mediterranean Sea, Malta']");
		for (int second = 0;; second++) {
			if (second >= 60) fail("could not find text 'Search for another spot or correct data'");
			try { if ("Search for another spot or correct data".equals(sel.getText("//div[@id='correct_submit_spot_data']/label"))) break; } catch (Exception e) {}
			Thread.sleep(1000);
		}

		// Profile
		System.out.println("Profile.."); 
		sel.click("link=Profile Data");
		sel.click("wizard_import_btn");
		waitForVisible("wizard_plugin_detect_extract");
		

		sel.select("wizard_computer_select1", "label=Emulator 1 - 1 dive - Using Suunto driver");
		sel.click("wizard_plugin_detect_extract");
		
		waitForVisible("wizard_dive_profile");
		

		verifyEquals("2010-07-31", sel.getValue("wizard-date"));
		verifyEquals("14", sel.getValue("wizard-time-in-hrs"));
		verifyEquals("34", sel.getValue("wizard-time-in-mins"));
		verifyEquals("66", sel.getValue("wizard-duration-mins"));
		verifyEquals("28.7", sel.getValue("wizard-max-depth"));
		verifyEquals("Delete profile or Import from file/computer", sel.getText("wizard_delete_graph"));
		
		
		sel.type("wizard-surface-temperature", "33");
		sel.type("wizard-bottom-temperature", "19");
		sel.type("stop_time", "3");
		
		// * with safety stops for profile
		sel.click("addsafetystops");
		sel.click("//div[@id='profile_table']/table[1]/tbody/tr[6]/td[2]/input[1]");
		sel.type("//div[@id='profile_table']/table[1]/tbody/tr[6]/td[2]/input[1]", "6");
		sel.type("//div[@id='profile_table']/table[1]/tbody/tr[6]/td[2]/input[2]", "3");
		sel.click("addsafetystops");
		sel.type("//div[@id='profile_table']/table[1]/tbody/tr[7]/td[2]/input[1]", "7");
		sel.type("//div[@id='profile_table']/table[1]/tbody/tr[7]/td[2]/input[2]", "4");
		sel.click("link=Del");
		
		// * with Dive Notes
		
		System.out.println("Dive Notes.."); 
		sel.click("link=Dive Notes");
		
		waitForVisible("wizard-dive-notes");
		

		sel.type("wizard-dive-notes", test_note);
		
		sel.click("//input[@value='recreational']");
		sel.click("//input[@value='training']");
		sel.click("//input[@value='night dive']");
		sel.click("//input[@value='deep dive']");
		sel.click("//input[@value='drift']");
		sel.click("//input[@value='wreck']");
		sel.click("//input[@value='cave']");
		sel.click("//input[@value='reef']");
		sel.click("//input[@value='photo']");
		sel.click("//input[@value='research']");
		sel.type("wizard_divetype_other", "test1, test2, test3,test4,test5");
		
		
		// * with Fish Data
		System.out.println("Fish Data.."); 
		sel.click("link=Fish Data");
	
		sel.click("//div[@id='wizard_content']/ul/li/input");
		sel.typeKeys("//div[@id='wizard_content']/ul/li/input", "clown");
		waitForElement("//li[.='Anemonefishes and Clownfishes']");
		
		try {
		sel.mouseOver("//li[.='Anemonefishes and Clownfishes']");
		sel.mouseDown("//li[.='Anemonefishes and Clownfishes']");
		} catch (Exception e) {
			System.out.println("could not add Anemonefishes and Clownfishes!" + e.getMessage());}
		
		sel.click("//div[@id='wizard_content']/ul/li/input");
		sel.typeKeys("//div[@id='wizard_content']/ul/li/input", "grouper");
		
		waitForElement("//li[.='Gulf grouper']");
		
		try {
		sel.mouseOver("//li[.='Gulf grouper']");
		sel.mouseDown("//li[.='Gulf grouper']");
		} catch (Exception e) {
								System.out.println("could not add Gulf grouper fish!" + e.getMessage());}

		// * with 	Pictures
		System.out.println("Pictures.."); 
		sel.click("link=Pictures");
		
		waitForVisible("wizard_pict_url");
		
		

		// add picasa pic
		sel.type("wizard_pict_url", "https://picasaweb.google.com/103180330852418292309/GreatBarrierReef#5455929773960873746");
		sel.click("wizard_add_pict_button");
		
		waitForElement("//div[@id='galleria-wizard']/div/div[1]/div[1]/div[2]/img");
		/*
		for (int second = 0;; second++) {
			if (second >= 60) fail("timeout");
			try { if (sel.isElementPresent("//div[@id='galleria-wizard']/div/div[1]/div[1]/div[2]/img")) break; } catch (Exception e) {}
			Thread.sleep(1000);
		}
*/
	//sdd fb pic	
		sel.type("wizard_pict_url", "http://www.facebook.com/photo.php?fbid=134707619941071&set=a.134707603274406.34094.100002055014409&type=1&theater");
		sel.click("wizard_add_pict_button");
		
		waitForElement("//img[contains(@src,'http://a8.sphotos.ak.fbcdn.net/hphotos-ak-snc6/248590_134707619941071_100002055014409_237219_900092_n.jpg')]");
		/*
		for (int second = 0;; second++) {
			if (second >= 60) fail("timeout");
			try { if (sel.isElementPresent("//img[contains(@src,'http://a8.sphotos.ak.fbcdn.net/hphotos-ak-snc6/248590_134707619941071_100002055014409_237219_900092_n.jpg')]")) break; } catch (Exception e) {}
			Thread.sleep(1000);
		} */
		
		
		// add flickr pic
		sel.type("wizard_pict_url", "http://www.flickr.com/photos/sbailliez/3434813100/");
		sel.click("wizard_add_pict_button");
		waitForElement("//img[contains(@src,'http://farm4.static.flickr.com/3337/3434813100_6064127dab.jpg')]");
		
		
		//add *.jpg url  http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg
		
		sel.type("wizard_pict_url", "http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg");
		sel.click("wizard_add_pict_button");
		waitForElement("//img[contains(@src,'http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg')]");
		
		
		//add youtube video http://youtu.be/i861adrvBZ4
		
		sel.type("wizard_pict_url", "http://youtu.be/i861adrvBZ4");
		sel.click("wizard_add_pict_button");
		waitForElement("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div[5]/img");
		
				
		// set favourite picture
		
		sel.click("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div[3]/img");
		sel.click("wizard_pict_set_fave");
		
	//	verifyTrue(sel.isTextPresent("Favorite pic #3"));
		verifyEquals(sel.getText("favoritepic"), "Favorite pic #3 |");
		
		
		fav_pic_local_addr = sel.getAttribute("//div[2]/div/div[3]/img@src");
		
 //add incorrect link
/*		
		sel.type("wizard_pict_url", "http://youtu.be/1234");
		try{
		sel.click("wizard_add_pict_button");} 
		catch (Exception e) {
			verifyTrue(sel.getAlert().startsWith("Unrecognized picture url, sorry!"));
			verifyTrue(sel.isElementPresent("dialog"));
		}
		
	*/	
		
		verifyTrue(sel.isElementPresent("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div[1]/img"));
		verifyTrue(sel.isElementPresent("//div[@id='galleria-wizard']/div/div[2]/div[2]/div/div/img"));
		verifyTrue(sel.isElementPresent("//img[contains(@src,'http://a6.sphotos.ak.fbcdn.net/hphotos-ak-snc6/216041_103492703072973_100002367311036_33469_1227396_n.jpg')]"));
		verifyTrue(sel.isElementPresent("//img[contains(@src,'http://farm4.static.flickr.com/3337/3434813100_6064127dab.jpg')]"));
		
		
		for(int j=0;j<100;j++)
		{
			sel.type("wizard_pict_url", "https://lh4.googleusercontent.com/-p6DhBXRbfgs/ThS9ER5qnMI/AAAAAAAAGjw/1SskeNwdpwE/s912/DSC_3474-scale.jpg");
			sel.click("wizard_add_pict_button");
			waitForElement("//img[contains(@src,'https://lh4.googleusercontent.com/-p6DhBXRbfgs/ThS9ER5qnMI/AAAAAAAAGjw/1SskeNwdpwE/s912/DSC_3474-scale.jpg')]");
			
		}
		
		
		sel.click("wizard_save");
		waitForVisible("css=span.fwb.fcb");
		waitForElement("//div[@id='main_content_area']/div[1]/ul[1]/li[1]/span");
		

	//	String host = sel.getEval("window.document.domain");
		url_new_dive = sel.getLocation();
		System.out.println("New Dive created. " + url_new_dive);
		
	}

}
