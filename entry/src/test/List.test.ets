import localUnitTest from './LocalUnit.test';
import moneyUtilTest from './MoneyUtil.test';
import expressionEngineTest from './ExpressionEngine.test';
import dateUtilTest from './DateUtil.test';
import periodResolverTest from './PeriodResolver.test';
import csvFormatTest from './CsvFormat.test';
import csvParserTest from './CsvParser.test';
import backupFormatTest from './BackupFormat.test';
import pinyinUtilTest from './PinyinUtil.test';

export default function testsuite() {
  localUnitTest();
  moneyUtilTest();
  expressionEngineTest();
  dateUtilTest();
  periodResolverTest();
  csvFormatTest();
  csvParserTest();
  backupFormatTest();
  pinyinUtilTest();
}
