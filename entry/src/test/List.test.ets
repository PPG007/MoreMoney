import localUnitTest from './LocalUnit.test';
import moneyUtilTest from './MoneyUtil.test';
import expressionEngineTest from './ExpressionEngine.test';

export default function testsuite() {
  localUnitTest();
  moneyUtilTest();
  expressionEngineTest();
}
