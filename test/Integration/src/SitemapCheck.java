import java.net.URL;

import org.apache.jasper.tagplugins.jstl.core.Url;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.htmlunit.HtmlUnitDriver;
import org.openqa.selenium.remote.CommandExecutor;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;

import com.thoughtworks.selenium.*;




import def.constant;
import diveboard.WebdriverMethods;


public class SitemapCheck extends WebdriverMethods {
//	protected static  Selenium sel;
//	protected static boolean local;
	
	
	

@Test
public void main() throws Exception {
	open("http://diveboard.com/sitemap.xml");
	waitForElement("//a[contains(text(),'http://www.diveboard.com')]");
		verifyEquals("XML Sitemap", getText("css=h1"));
		verifyTrue(getText("id=intro").contains("This is a XML Sitemap which is supposed to be processed by search engines like Google, MSN Search and YAHOO.\n You can find more information about XML sitemaps on sitemaps.org and Google's list of sitemap programs.") );
		verifyTrue(isElementPresent("link=exact:http://www.diveboard.com"));
		verifyEquals("100%", getText("//td[2]"));
		verifyEquals("Daily", getText("//td[3]"));
		verifyTrue(isElementPresent("link=exact:http://www.diveboard.com/explore"));
		verifyTrue(isElementPresent("link=exact:http://www.diveboard.com/blog/about/"));
		verifyTrue(isElementPresent("link=exact:http://www.diveboard.com/ksso/21"));

		
		
			
	
	
}
@After
public void close() throws Exception {
closeBrowser();
}

}
