#!/bin/bash

# ============================================
# آموزش جامع: grep, sed, awk
# از مبتدی تا حرفه‌ای - صفر تا صد
# ============================================

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# تابع برای نمایش عنوان بخش
show_section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# تابع برای نمایش مثال
show_example() {
    echo -e "${YELLOW}مثال: $1${NC}"
    echo -e "${BLUE}دستور:${NC} $2"
    echo ""
}

# ============================================
# بخش 1: GREP - جستجوی متن
# ============================================

show_section "🔍 بخش 1: GREP - جستجوی متن در فایل‌ها"

echo -e "${GREEN}GREP چیست؟${NC}"
echo "grep = Global Regular Expression Print"
echo "برای جستجوی الگوها در فایل‌ها و خروجی دستورات استفاده می‌شود"
echo ""

# ایجاد فایل نمونه برای تست
cat > sample_log.txt << 'EOF'
2024-01-15 10:30:45 INFO User login successful
2024-01-15 10:31:12 ERROR Database connection failed
2024-01-15 10:32:00 INFO User logout
2024-01-15 10:33:22 WARNING High memory usage detected
2024-01-15 10:34:10 ERROR File not found: config.json
2024-01-15 10:35:00 INFO System backup completed
2024-01-15 10:36:15 ERROR Permission denied
2024-01-15 10:37:30 INFO Cache cleared successfully
EOF

cat > sample_data.txt << 'EOF'
Ali:25:Developer:Tehran
Reza:30:Designer:Isfahan
Sara:28:Manager:Shiraz
Mohammad:35:Engineer:Tabriz
Fateme:22:Student:Mashhad
Hassan:40:Director:Tehran
EOF

echo -e "${GREEN}✅ فایل‌های نمونه ایجاد شدند${NC}"
echo ""

# ========== سطح مبتدی GREP ==========
show_section "📚 سطح مبتدی - GREP"

show_example "1. جستجوی ساده" "grep 'ERROR' sample_log.txt"
echo "نتیجه:"
grep 'ERROR' sample_log.txt
echo ""

show_example "2. جستجو با حساسیت به حروف" "grep -i 'error' sample_log.txt"
echo "نتیجه:"
grep -i 'error' sample_log.txt
echo ""

show_example "3. نمایش شماره خط" "grep -n 'INFO' sample_log.txt"
echo "نتیجه:"
grep -n 'INFO' sample_log.txt
echo ""

show_example "4. شمارش تعداد خطوط" "grep -c 'ERROR' sample_log.txt"
echo "نتیجه:"
grep -c 'ERROR' sample_log.txt
echo ""

show_example "5. نمایش خطوط قبل و بعد" "grep -A 2 -B 2 'ERROR' sample_log.txt"
echo "نتیجه:"
grep -A 2 -B 2 'ERROR' sample_log.txt
echo ""

# ========== سطح متوسط GREP ==========
show_section "📖 سطح متوسط - GREP"

show_example "6. جستجوی چند الگو" "grep -E 'ERROR|WARNING' sample_log.txt"
echo "نتیجه:"
grep -E 'ERROR|WARNING' sample_log.txt
echo ""

show_example "7. معکوس کردن (خطوط بدون الگو)" "grep -v 'INFO' sample_log.txt"
echo "نتیجه:"
grep -v 'INFO' sample_log.txt
echo ""

show_example "8. جستجو در چند فایل" "grep 'ERROR' sample_log.txt sample_data.txt"
echo "نتیجه:"
grep 'ERROR' sample_log.txt sample_data.txt 2>/dev/null || echo "فقط در sample_log.txt پیدا شد"
echo ""

show_example "9. جستجو با regex - شروع خط" "grep '^2024' sample_log.txt"
echo "نتیجه:"
grep '^2024' sample_log.txt
echo ""

show_example "10. جستجو با regex - پایان خط" "grep 'successful$' sample_log.txt"
echo "نتیجه:"
grep 'successful$' sample_log.txt
echo ""

# ========== سطح پیشرفته GREP ==========
show_section "🚀 سطح پیشرفته - GREP"

show_example "11. جستجو با کلاس کاراکتر" "grep '[0-9]' sample_data.txt"
echo "نتیجه:"
grep '[0-9]' sample_data.txt
echo ""

show_example "12. جستجو با تکرار" "grep -E 'E{2,}' sample_log.txt"
echo "نتیجه:"
grep -E 'E{2,}' sample_log.txt
echo ""

show_example "13. جستجو در دایرکتوری" "grep -r 'ERROR' . 2>/dev/null | head -5"
echo "نتیجه:"
grep -r 'ERROR' . 2>/dev/null | head -5
echo ""

show_example "14. نمایش فقط نام فایل" "grep -l 'ERROR' sample_log.txt"
echo "نتیجه:"
grep -l 'ERROR' sample_log.txt
echo ""

show_example "15. جستجو با رنگ" "grep --color=always 'ERROR' sample_log.txt"
echo "نتیجه:"
grep --color=always 'ERROR' sample_log.txt
echo ""

# ============================================
# بخش 2: SED - ویرایش جریان متن
# ============================================

show_section "✂️ بخش 2: SED - ویرایش جریان متن"

echo -e "${GREEN}SED چیست؟${NC}"
echo "sed = Stream Editor"
echo "برای ویرایش و تبدیل متن در خطوط استفاده می‌شود"
echo ""

# ایجاد فایل نمونه
cat > sample_config.txt << 'EOF'
server_name=localhost
port=8080
database=myapp
username=admin
password=secret123
debug=true
EOF

echo -e "${GREEN}✅ فایل نمونه ایجاد شد${NC}"
echo ""

# ========== سطح مبتدی SED ==========
show_section "📚 سطح مبتدی - SED"

show_example "1. جایگزینی ساده" "sed 's/ERROR/خطا/g' sample_log.txt"
echo "نتیجه:"
sed 's/ERROR/خطا/g' sample_log.txt
echo ""

show_example "2. جایگزینی فقط اولین مورد" "sed 's/INFO/اطلاعات/' sample_log.txt | head -3"
echo "نتیجه:"
sed 's/INFO/اطلاعات/' sample_log.txt | head -3
echo ""

show_example "3. حذف خطوط" "sed '/ERROR/d' sample_log.txt"
echo "نتیجه:"
sed '/ERROR/d' sample_log.txt
echo ""

show_example "4. نمایش خطوط خاص" "sed -n '2,5p' sample_log.txt"
echo "نتیجه:"
sed -n '2,5p' sample_log.txt
echo ""

show_example "5. درج متن قبل از خط" "sed '3i\\--- خط جدید ---' sample_log.txt | head -5"
echo "نتیجه:"
sed '3i\\--- خط جدید ---' sample_log.txt | head -5
echo ""

# ========== سطح متوسط SED ==========
show_section "📖 سطح متوسط - SED"

show_example "6. جایگزینی با regex" "sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/تاریخ/g' sample_log.txt | head -3"
echo "نتیجه:"
sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/تاریخ/g' sample_log.txt | head -3
echo ""

show_example "7. استفاده از گروه‌ها" "echo 'Ali 25' | sed 's/\([A-Za-z]*\) \([0-9]*\)/نام: \1, سن: \2/'"
echo "نتیجه:"
echo 'Ali 25' | sed 's/\([A-Za-z]*\) \([0-9]*\)/نام: \1, سن: \2/'
echo ""

show_example "8. جایگزینی در فایل" "cp sample_config.txt temp_config.txt && sed -i 's/localhost/example.com/g' temp_config.txt && cat temp_config.txt"
echo "نتیجه:"
cp sample_config.txt temp_config.txt
sed -i 's/localhost/example.com/g' temp_config.txt 2>/dev/null || sed -i '' 's/localhost/example.com/g' temp_config.txt
cat temp_config.txt
rm -f temp_config.txt
echo ""

show_example "9. چندین جایگزینی" "sed -e 's/ERROR/خطا/g' -e 's/INFO/اطلاعات/g' sample_log.txt | head -3"
echo "نتیجه:"
sed -e 's/ERROR/خطا/g' -e 's/INFO/اطلاعات/g' sample_log.txt | head -3
echo ""

show_example "10. شرطی کردن جایگزینی" "sed '/ERROR/s/2024/سال 2024/g' sample_log.txt"
echo "نتیجه:"
sed '/ERROR/s/2024/سال 2024/g' sample_log.txt
echo ""

# ========== سطح پیشرفته SED ==========
show_section "🚀 سطح پیشرفته - SED"

show_example "11. استفاده از فایل اسکریپت" "echo 's/ERROR/خطا/g\ns/INFO/اطلاعات/g' > sed_script.txt && sed -f sed_script.txt sample_log.txt | head -3"
echo "نتیجه:"
echo 's/ERROR/خطا/g
s/INFO/اطلاعات/g' > sed_script.txt
sed -f sed_script.txt sample_log.txt | head -3
rm -f sed_script.txt
echo ""

show_example "12. جایگزینی با مرجع" "sed 's/\(.*\):\(.*\):\(.*\):\(.*\)/شهر: \4, نام: \1/' sample_data.txt"
echo "نتیجه:"
sed 's/\(.*\):\(.*\):\(.*\):\(.*\)/شهر: \4, نام: \1/' sample_data.txt
echo ""

show_example "13. حذف خطوط خالی" "echo -e 'خط 1\n\nخط 2\n  \nخط 3' | sed '/^$/d'"
echo "نتیجه:"
echo -e 'خط 1\n\nخط 2\n  \nخط 3' | sed '/^$/d'
echo ""

show_example "14. تبدیل به حروف بزرگ" "sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' <<< 'hello world'"
echo "نتیجه:"
sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' <<< 'hello world'
echo ""

show_example "15. خواندن از فایل دیگر" "sed '/INFO/r sample_data.txt' sample_log.txt | head -10"
echo "نتیجه:"
sed '/INFO/r sample_data.txt' sample_log.txt | head -10
echo ""

# ============================================
# بخش 3: AWK - پردازش داده‌های ساختاریافته
# ============================================

show_section "⚙️ بخش 3: AWK - پردازش داده‌های ساختاریافته"

echo -e "${GREEN}AWK چیست؟${NC}"
echo "awk = Aho, Weinberger, Kernighan (نام سازندگان)"
echo "یک زبان برنامه‌نویسی کامل برای پردازش فایل‌های متنی ساختاریافته"
echo ""

# ========== سطح مبتدی AWK ==========
show_section "📚 سطح مبتدی - AWK"

show_example "1. چاپ ستون‌ها" "awk '{print \$1}' sample_data.txt"
echo "نتیجه:"
awk '{print $1}' sample_data.txt
echo ""

show_example "2. چاپ چند ستون" "awk '{print \$1, \$4}' sample_data.txt"
echo "نتیجه:"
awk '{print $1, $4}' sample_data.txt
echo ""

show_example "3. استفاده از جداکننده" "awk -F: '{print \$1, \$3}' sample_data.txt"
echo "نتیجه:"
awk -F: '{print $1, $3}' sample_data.txt
echo ""

show_example "4. فیلتر کردن خطوط" "awk -F: '\$2 > 28 {print \$1, \$2}' sample_data.txt"
echo "نتیجه:"
awk -F: '$2 > 28 {print $1, $2}' sample_data.txt
echo ""

show_example "5. شمارش خطوط" "awk 'END {print NR}' sample_data.txt"
echo "نتیجه:"
awk 'END {print NR}' sample_data.txt
echo ""

# ========== سطح متوسط AWK ==========
show_section "📖 سطح متوسط - AWK"

show_example "6. محاسبات ریاضی" "awk -F: '{sum += \$2} END {print \"مجموع سن‌ها:\", sum}' sample_data.txt"
echo "نتیجه:"
awk -F: '{sum += $2} END {print "مجموع سن‌ها:", sum}' sample_data.txt
echo ""

show_example "7. محاسبه میانگین" "awk -F: '{sum += \$2; count++} END {print \"میانگین سن:\", sum/count}' sample_data.txt"
echo "نتیجه:"
awk -F: '{sum += $2; count++} END {print "میانگین سن:", sum/count}' sample_data.txt
echo ""

show_example "8. شرط‌های پیچیده" "awk -F: '\$2 >= 25 && \$2 <= 35 {print \$1, \"سن:\", \$2}' sample_data.txt"
echo "نتیجه:"
awk -F: '$2 >= 25 && $2 <= 35 {print $1, "سن:", $2}' sample_data.txt
echo ""

show_example "9. استفاده از متغیرها" "awk -F: '{name=\$1; age=\$2; if(age>30) print name, \"بزرگتر از 30\"}' sample_data.txt"
echo "نتیجه:"
awk -F: '{name=$1; age=$2; if(age>30) print name, "بزرگتر از 30"}' sample_data.txt
echo ""

show_example "10. گروه‌بندی و شمارش" "awk -F: '{city[\$4]++} END {for(c in city) print c, city[c]}' sample_data.txt"
echo "نتیجه:"
awk -F: '{city[$4]++} END {for(c in city) print c, city[c]}' sample_data.txt
echo ""

# ========== سطح پیشرفته AWK ==========
show_section "🚀 سطح پیشرفته - AWK"

show_example "11. BEGIN و END" "awk 'BEGIN {print \"شروع پردازش\"} {print \$1} END {print \"پایان پردازش\"}' sample_data.txt"
echo "نتیجه:"
awk 'BEGIN {print "شروع پردازش"} {print $1} END {print "پایان پردازش"}' sample_data.txt
echo ""

show_example "12. توابع رشته‌ای" "awk '{print toupper(\$1), length(\$1)}' sample_data.txt"
echo "نتیجه:"
awk '{print toupper($1), length($1)}' sample_data.txt
echo ""

show_example "13. فرمت‌دهی خروجی" "awk -F: '{printf \"%-10s %3d سال\n\", \$1, \$2}' sample_data.txt"
echo "نتیجه:"
awk -F: '{printf "%-10s %3d سال\n", $1, $2}' sample_data.txt
echo ""

show_example "14. پردازش چند فایل" "awk '{print FILENAME, \$0}' sample_log.txt sample_data.txt | head -5"
echo "نتیجه:"
awk '{print FILENAME, $0}' sample_log.txt sample_data.txt | head -5
echo ""

show_example "15. اسکریپت AWK پیچیده" "awk -F: '{
    if (\$2 < 25) category = \"جوان\"
    else if (\$2 < 35) category = \"میانسال\"
    else category = \"مسن\"
    print \$1, \"در دسته\", category
}' sample_data.txt"
echo "نتیجه:"
awk -F: '{
    if ($2 < 25) category = "جوان"
    else if ($2 < 35) category = "میانسال"
    else category = "مسن"
    print $1, "در دسته", category
}' sample_data.txt
echo ""

# ============================================
# بخش 4: ترکیب ابزارها
# ============================================

show_section "🔗 بخش 4: ترکیب grep, sed, awk"

show_example "1. grep + sed" "grep 'ERROR' sample_log.txt | sed 's/ERROR/خطا/g'"
echo "نتیجه:"
grep 'ERROR' sample_log.txt | sed 's/ERROR/خطا/g'
echo ""

show_example "2. grep + awk" "grep 'INFO' sample_log.txt | awk '{print \$1, \$2, \$NF}'"
echo "نتیجه:"
grep 'INFO' sample_log.txt | awk '{print $1, $2, $NF}'
echo ""

show_example "3. sed + awk" "sed 's/ERROR/خطا/g' sample_log.txt | awk '/خطا/ {print NR, \$0}'"
echo "نتیجه:"
sed 's/ERROR/خطا/g' sample_log.txt | awk '/خطا/ {print NR, $0}'
echo ""

show_example "4. زنجیره کامل" "grep -E 'ERROR|WARNING' sample_log.txt | sed 's/2024-01-15/تاریخ/g' | awk '{print \"خط\", NR, \":\", \$0}'"
echo "نتیجه:"
grep -E 'ERROR|WARNING' sample_log.txt | sed 's/2024-01-15/تاریخ/g' | awk '{print "خط", NR, ":", $0}'
echo ""

# ============================================
# بخش 5: مثال‌های کاربردی واقعی
# ============================================

show_section "💼 بخش 5: مثال‌های کاربردی واقعی"

echo -e "${GREEN}مثال 1: تحلیل لاگ سرور${NC}"
echo "استخراج خطاها و شمارش آن‌ها:"
grep 'ERROR' sample_log.txt | awk '{print $NF}' | sort | uniq -c | sort -rn
echo ""

echo -e "${GREEN}مثال 2: تبدیل فرمت داده${NC}"
echo "تبدیل CSV به فرمت خوانا:"
awk -F: 'BEGIN {printf "%-12s %-5s %-15s %-10s\n", "نام", "سن", "شغل", "شهر"; print "============================================"} {printf "%-12s %-5s %-15s %-10s\n", $1, $2, $3, $4}' sample_data.txt
echo ""

echo -e "${GREEN}مثال 3: پاکسازی و فرمت‌دهی${NC}"
echo "استخراج و فرمت‌دهی تاریخ و زمان:"
awk '{print "تاریخ:", $1, "| زمان:", $2, "| پیام:", substr($0, index($0,$3))}' sample_log.txt | head -3
echo ""

echo -e "${GREEN}مثال 4: گزارش آماری${NC}"
echo "گزارش کامل از داده‌ها:"
awk -F: 'BEGIN {
    print "=== گزارش آماری ==="
    print ""
}
{
    sum += $2
    count++
    if ($2 > max || max == 0) max = $2
    if ($2 < min || min == 0) min = $2
    cities[$4]++
}
END {
    print "تعداد کل:", count
    print "میانگین سن:", sum/count
    print "بیشترین سن:", max
    print "کمترین سن:", min
    print ""
    print "توزیع بر اساس شهر:"
    for (c in cities) print "  ", c, ":", cities[c]
}' sample_data.txt
echo ""

# ============================================
# خلاصه و نکات مهم
# ============================================

show_section "📝 خلاصه و نکات مهم"

echo -e "${GREEN}نکات GREP:${NC}"
echo "• -i: حساسیت به حروف را غیرفعال می‌کند"
echo "• -n: شماره خط را نمایش می‌دهد"
echo "• -v: معکوس کردن (خطوط بدون الگو)"
echo "• -E: فعال‌سازی regex پیشرفته"
echo "• -r: جستجوی بازگشتی در دایرکتوری"
echo ""

echo -e "${GREEN}نکات SED:${NC}"
echo "• s/old/new/g: جایگزینی همه موارد"
echo "• s/old/new/: جایگزینی فقط اولین مورد"
echo "• /pattern/d: حذف خطوط"
echo "• -i: ویرایش مستقیم فایل"
echo "• -n + p: نمایش فقط خطوط انتخاب شده"
echo ""

echo -e "${GREEN}نکات AWK:${NC}"
echo "• -F: تعیین جداکننده فیلد"
echo "• \$1, \$2, ...: فیلدهای اول، دوم، ..."
echo "• \$0: کل خط"
echo "• \$NF: آخرین فیلد"
echo "• NR: شماره خط جاری"
echo "• BEGIN/END: اجرا در ابتدا/انتها"
echo ""

echo -e "${GREEN}💡 نکته طلایی:${NC}"
echo "این ابزارها را می‌توانید با pipe (|) ترکیب کنید"
echo "مثال: cat file.txt | grep 'pattern' | sed 's/old/new/g' | awk '{print \$1}'"
echo ""

# پاکسازی فایل‌های موقت
echo -e "${YELLOW}پاکسازی فایل‌های موقت...${NC}"
rm -f sample_log.txt sample_data.txt sample_config.txt
echo -e "${GREEN}✅ پاکسازی انجام شد${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}🎉 آموزش به پایان رسید!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "برای اجرای این آموزش:"
echo "  chmod +x جستجو_و_پردازش_متن.sh"
echo "  ./جستجو_و_پردازش_متن.sh"
echo ""

