import Foundation

/// 内置演示词表：无网络 / 未下载完整词典时的兜底数据。
///
/// 覆盖日常高频实词（食物 / 自然 / 科技 / 生活 / 情绪 / 动物 / 动词短语 /
/// 形容词 / 网络流行语），保证首次安装后即可完整体验。
/// 拼音为参考值，完整词典以下载的 CC-CEDICT 为准。
public enum BuiltinDictionary {

    public static func entries() -> [DictionaryEntry] {
        func entry(_ simplified: String, _ pinyin: String, _ glosses: [String]) -> DictionaryEntry {
            DictionaryEntry(simplified: simplified, pinyin: pinyin, glosses: glosses)
        }
        return [
            // 饮食
            entry("咖啡", "ka1 fei1", ["coffee"]),
            entry("奶茶", "nai3 cha2", ["milk tea", "bubble tea"]),
            entry("啤酒", "pi2 jiu3", ["beer"]),
            entry("面包", "mian4 bao1", ["bread"]),
            entry("蛋糕", "dan4 gao1", ["cake"]),
            entry("火锅", "huo3 guo1", ["hot pot"]),
            entry("冰淇淋", "bing1 qi2 lin2", ["ice cream"]),
            entry("巧克力", "qiao3 ke4 li4", ["chocolate"]),
            entry("水果", "shui3 guo3", ["fruit"]),
            entry("西瓜", "xi1 gua1", ["watermelon"]),
            // 自然
            entry("天气", "tian1 qi4", ["weather"]),
            entry("太阳", "tai4 yang2", ["sun"]),
            entry("月亮", "yue4 liang4", ["the moon"]),
            entry("星星", "xing1 xing1", ["star", "stars"]),
            entry("下雨", "xia4 yu3", ["to rain"]),
            entry("下雪", "xia4 xue3", ["to snow"]),
            entry("彩虹", "cai3 hong2", ["rainbow"]),
            entry("海洋", "hai3 yang2", ["ocean", "sea"]),
            entry("森林", "sen1 lin2", ["forest"]),
            entry("花朵", "hua1 duo3", ["flower", "blossom"]),
            // 科技
            entry("电脑", "dian4 nao3", ["computer"]),
            entry("手机", "shou3 ji1", ["mobile phone", "cell phone"]),
            entry("网络", "wang3 luo4", ["network", "internet"]),
            entry("软件", "ruan3 jian4", ["software"]),
            entry("键盘", "jian4 pan2", ["keyboard"]),
            entry("屏幕", "ping2 mu4", ["screen"]),
            entry("电池", "dian4 chi2", ["battery"]),
            entry("充电", "chong1 dian4", ["to charge (a battery)"]),
            entry("相机", "xiang4 ji1", ["camera"]),
            // 生活
            entry("地铁", "di4 tie3", ["subway", "metro"]),
            entry("公交", "gong1 jiao1", ["public transportation", "bus"]),
            entry("打车", "da3 che1", ["to take a taxi"]),
            entry("加班", "jia1 ban1", ["to work overtime"]),
            entry("会议", "hui4 yi4", ["meeting", "conference"]),
            entry("邮件", "you2 jian4", ["mail", "email"]),
            entry("快递", "kuai4 di4", ["express delivery"]),
            entry("外卖", "wai4 mai4", ["takeout", "food delivery"]),
            entry("超市", "chao1 shi4", ["supermarket"]),
            entry("医院", "yi1 yuan4", ["hospital"]),
            entry("银行", "yin2 hang2", ["bank"]),
            entry("电影", "dian4 ying3", ["movie", "film"]),
            entry("音乐", "yin1 yue4", ["music"]),
            entry("旅行", "lv3 xing2", ["travel", "journey"]),
            entry("酒店", "jiu3 dian4", ["hotel"]),
            entry("护照", "hu4 zhao4", ["passport"]),
            entry("机场", "ji1 chang3", ["airport"]),
            // 学习
            entry("单词", "dan1 ci2", ["word"]),
            entry("英语", "ying1 yu3", ["English (language)"]),
            entry("考试", "kao3 shi4", ["exam", "test"]),
            entry("复习", "fu4 xi2", ["to review", "to revise"]),
            entry("笔记", "bi3 ji4", ["notes"]),
            entry("知识", "zhi1 shi4", ["knowledge"]),
            entry("图书馆", "tu2 shu1 guan3", ["library"]),
            // 情绪
            entry("开心", "kai1 xin1", ["happy"]),
            entry("难过", "nan2 guo4", ["sad", "unhappy"]),
            entry("生气", "sheng1 qi4", ["angry"]),
            entry("感动", "gan3 dong4", ["moved", "touched"]),
            entry("紧张", "jin3 zhang1", ["nervous"]),
            entry("放松", "fang4 song1", ["to relax"]),
            // 动物
            entry("猫咪", "mao1 mi1", ["kitty", "cat"]),
            entry("小狗", "xiao3 gou3", ["puppy", "little dog"]),
            entry("熊猫", "xiong2 mao1", ["panda"]),
            entry("老虎", "lao3 hu3", ["tiger"]),
            // 动词短语
            entry("跑步", "pao3 bu4", ["to run", "jogging"]),
            entry("游泳", "you2 yong3", ["to swim", "swimming"]),
            entry("拍照", "pai1 zhao4", ["to take a photo"]),
            entry("散步", "san4 bu4", ["to take a walk"]),
            entry("睡觉", "shui4 jiao4", ["to sleep"]),
            entry("购物", "gou4 wu4", ["shopping"]),
            entry("旅游", "lv3 you2", ["tourism", "to travel"]),
            // 形容词
            entry("漂亮", "piao4 liang4", ["beautiful", "pretty"]),
            entry("好吃", "hao3 chi1", ["delicious", "tasty"]),
            entry("便宜", "pian2 yi2", ["cheap", "inexpensive"]),
            entry("昂贵", "ang2 gui4", ["expensive"]),
            entry("方便", "fang1 bian4", ["convenient"]),
            entry("麻烦", "ma2 fan5", ["troublesome", "inconvenient"]),
            entry("奇怪", "qi2 guai4", ["strange", "odd"]),
            entry("厉害", "li4 hai4", ["amazing", "awesome"]),
            entry("靠谱", "kao4 pu3", ["reliable", "trustworthy"]),
            // 网络流行语
            entry("打工人", "da3 gong1 ren2", ["worker", "office worker"]),
            entry("内卷", "nei4 juan3", ["involution", "cutthroat competition"]),
            entry("躺平", "tang3 ping2", ["to lie flat", "to give up striving"]),
            entry("点赞", "dian3 zan4", ["to like (on social media)", "to give a thumbs-up"]),
            entry("吐槽", "tu3 cao2", ["to complain", "to mock"]),
            entry("种草", "zhong3 cao3", ["to recommend", "to tempt (into buying)"]),
            entry("摸鱼", "mo1 yu2", ["to slack off", "to goof off at work"]),
        ]
    }
}
