package diveboard;
import java.io.*;
import java.net.URL;


import org.apache.commons.io.FileUtils;
import org.junit.Before;
import org.openqa.selenium.By;
import org.openqa.selenium.HasInputDevices;
import org.openqa.selenium.Mouse;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebDriverBackedSelenium;
import org.openqa.selenium.WebElement;

import org.openqa.selenium.firefox.FirefoxDriver;

import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.internal.Locatable;

import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.support.ui.Select;

import com.thoughtworks.selenium.*;
import def.constant;

public class WebdriverMethods extends SeleneseTestBase {
	public static boolean local ;
	public static String url = constant.url ;
	public static int minute = constant.minute;
	protected static  Selenium sel;
	
	protected static WebDriver local_driver;
	protected static RemoteWebDriver	remote_driver;
//	private static ChromeDriverService service;

	@Before
	public void setUp() throws Exception {

		
		if(constant.checkLocal())	
			local = true;
			else 
				local = false;
		
	
	// local = false;
		

		
		if( local)
				{
				
				local_driver = new FirefoxDriver();
		
				}
			
		
		else
				remote_driver = new RemoteWebDriver(
                    new URL("http://172.16.0.14:4444/wd/hub"), 
                    DesiredCapabilities.firefox());
						
			
		sel = new WebDriverBackedSelenium(getWebDriver(), constant.url);

	}
	
	protected  void 	makeScreenshot(String pathname) throws IOException{
		  File scrFile = ((TakesScreenshot) getWebDriver()).getScreenshotAs(OutputType.FILE);
          //Needs Commons IO library
          	FileUtils.copyFile(scrFile, new File(pathname));
	}
	
	
	
	
	protected  void  waitForElement(String element) throws InterruptedException {
		
		for (int second = 0;; second++) {
			if (second >= minute) fail("FAIL: Element "+element +" was not found on page " + getWebDriver().getCurrentUrl());
			try { if (isElementPresent(element)) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		
		}	
	
	}
	
	
	protected  void  waitNoElement(String element) throws InterruptedException {
		
		for (int second = 0;; second++) {
			if (second >= minute) fail("FAIL: Element "+element +" is still on page " + getWebDriver().getCurrentUrl());
			try { if (!isElementPresent(element)) break; } 
			catch (Exception e) {System.out.println(e.getMessage());}
			Thread.sleep(1000);
		
		}	
	
	}
	
	public WebDriver getWebDriver(){
		  if(local)
		   return local_driver;
		  else
		   return remote_driver;
		 }
	
	public void open(String url)
	{
		getWebDriver().get(url);
	}

	
	public String getLocation()
	{
		return getWebDriver().getCurrentUrl();
		
	}
	public void click(String element) {
		
		getElement(element).click();
		
		}
	
	   public void clear(String element)
       {
           //clears textbox
		   getElement(element).clear();

       }
	
public void type(String element, String text) {
	getElement(element).sendKeys(text);
	
		}

public String getText(String element) {

	return getElement(element).getText();
	
		
		}

public void select(String element, String value){
	  Select select = new Select(getElement(element));
	  if(value.startsWith("value="))
	   select.selectByValue(value.replace("value=", ""));
	  else
		  if(value.startsWith("label="))
			   select.selectByVisibleText(value.replace("label=", ""));
		  else select.selectByVisibleText(value);
	
	 }

public String getAttribute(String value)
{ 

	if(value.lastIndexOf("@")>0)
return getElement(value.substring(0, value.lastIndexOf("@"))).
		getAttribute(value.substring(value.lastIndexOf("@")+1, value.length()));

	else System.out.println("!WARNING: incorrect value " +value +" for getAttribute");
	return "";

}
public void mouseOver(String element){

	
	//build and perform the mouseOver with Advanced User Interactions API
	Actions builder = new Actions(getWebDriver());    
	builder.moveToElement(getElement(element)).build().perform();
	
}

public void mouseDown(String element){

	Locatable hoverItem = (Locatable) getElement(element); 

	Mouse mouse = ((HasInputDevices) getWebDriver()).getMouse(); 
	mouse.mouseMove(hoverItem.getCoordinates()); 

	
}


public void mouseUp(String element){

	Locatable hoverItem = (Locatable) getElement(element); 

	Mouse mouse = ((HasInputDevices) getWebDriver()).getMouse(); 
	mouse.mouseUp(hoverItem.getCoordinates());

}

public void mouseMoveAt(String element, int x, int y){

	Locatable hoverItem = (Locatable) getElement(element); 

	Mouse mouse = ((HasInputDevices) getWebDriver()).getMouse(); 
	mouse.mouseMove(hoverItem.getCoordinates(), x, y);
	
}



public void dragAndDrop(String element, int x, int y){

	
	//build and perform the dragAndDropBy with Advanced User Interactions API
	Actions builder = new Actions(getWebDriver());    
	builder.dragAndDropBy(getElement(element), x, y).build().perform();

	
}

public void dragAndDropToObject(String element, String element1){

	
	//build and perform the dragAndDropBy with Advanced User Interactions API
	Actions builder = new Actions(getWebDriver());    
	builder.dragAndDrop(getElement(element),getElement(element1) ).build().perform();
	
}


public void closeBrowser(){
	
	getWebDriver().close();
}


 public boolean isVisible(String element)
{
	 try{
	 boolean result =  getElement(element).isDisplayed();
	 return result;
	 } catch(Exception e) {
		 return false;
	 }

}


public boolean isElementPresent(String element)
{
	if (element.startsWith("//"))
	{	try{
		return( getWebDriver().findElements(By.xpath(element)).size() > 0) ? true : false;
			} catch(Exception e) {return false;}
	//	System.out.println(temp);
	//	return ( temp > 0) ? true : false;
	}
	else if (element.startsWith("css="))
	{
		element = element.substring(4,element.length());
		return (getWebDriver().findElements(By.cssSelector(element)).size() > 0) ? true : false;
			
	}
	else if (element.startsWith("id="))
	{
		element = element.substring(3,element.length());
		return	(getWebDriver().findElements(By.id(element)).size() > 0) ? true : false;
	}
	
	else if (element.startsWith("link="))
	{
		element = element.substring(5,element.length());
		return	(getWebDriver().findElements(By.linkText(element)).size() > 0) ? true : false;
	}
	else 
	return	(getWebDriver().findElements(By.id(element)).size() > 0) ? true : false;

	
//return false;
}






WebElement getElement(String element)
{
	
	if (element.startsWith("//"))
		return getWebDriver().findElement(By.xpath(element));

else if (element.startsWith("css="))
{
	element = element.substring(4,element.length());
	return getWebDriver().findElement(By.cssSelector(element));
}
else if (element.startsWith("id="))
{
	element = element.substring(3,element.length());
	return getWebDriver().findElement(By.id(element));
}
	
else if (element.startsWith("link="))
{
	element = element.substring(5,element.length());
	return getWebDriver().findElement(By.linkText(element));
}
else if (element.startsWith("name="))
{
	element = element.substring(5,element.length());
	return getWebDriver().findElement(By.name(element));
}	
	
else 
	return getWebDriver().findElement(By.id(element));

	
	}
	


	
}
