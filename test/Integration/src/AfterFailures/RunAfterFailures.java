package AfterFailures;
import java.util.ArrayList;
import java.util.List;

import org.junit.internal.runners.model.MultipleFailureException;
import org.junit.runners.model.FrameworkMethod;
import org.junit.runners.model.Statement;

public class RunAfterFailures extends Statement {

    private final Statement fNext;

    private final Object fTarget;

    private final List<FrameworkMethod> fAfterFailures;
    
    public RunAfterFailures(Statement next, List<FrameworkMethod> afterFailures,
                            Object target) {
        fNext= next;
        fAfterFailures= afterFailures;
        fTarget= target;
    }

    @Override
    public void evaluate() throws Throwable {
        List<Throwable> fErrors = new ArrayList<Throwable>();
        fErrors.clear();
        try {
            fNext.evaluate();
        } catch (Throwable e) {
            fErrors.add(e);
            for (FrameworkMethod each : fAfterFailures) {
                try {
                    each.invokeExplosively(fTarget, e);
                } catch (Throwable e2) {
                    fErrors.add(e2);
                }
            }
        }
        if (fErrors.isEmpty()) {
            return;
        }
        if (fErrors.size() == 1) {
            throw fErrors.get(0);
        }
        throw new MultipleFailureException(fErrors);
    }

}
