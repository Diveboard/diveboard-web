
package AfterFailures;
import java.util.List;

import org.junit.runners.BlockJUnit4ClassRunner;
import org.junit.runners.model.FrameworkMethod;
import org.junit.runners.model.InitializationError;
import org.junit.runners.model.Statement;

/**
 * JUnit runner which runs all @AfterFailure methods in a test class.
 *
 */
public class RCRunner extends BlockJUnit4ClassRunner {

    /**
     * @param klass Test class
     * @throws InitializationError
     *             if the test class is malformed.
     */
    public RCRunner(Class<?> klass) throws InitializationError {
        super(klass);
    }

    /*
     * Override withAfters() so we can append to the statement which will invoke the test
     * method. We don't override methodBlock() because we wont be able to reference 
     * the target object. 
     */
    @Override
    protected Statement withAfters(FrameworkMethod method, Object target, 
                                   Statement statement) {
        statement = super.withAfters(method, target, statement);
        return withAfterFailures(method, target, statement);
    }

    protected Statement withAfterFailures(FrameworkMethod method, Object target, 
                                          Statement statement) {
        List<FrameworkMethod> failures =
            getTestClass().getAnnotatedMethods(AfterFailure.class);
        return new RunAfterFailures(statement, failures, target);
    }
}
