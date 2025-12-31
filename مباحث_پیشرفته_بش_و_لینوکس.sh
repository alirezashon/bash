#!/bin/bash

# ============================================
# آموزش جامع: مباحث پیشرفته Bash و Linux
# از مبتدی تا حرفه‌ای - صفر تا صد
# ============================================

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
    echo -e "${YELLOW}مثال $1:${NC}"
    echo -e "${BLUE}دستور:${NC} $2"
    if [ -n "$3" ]; then
        echo -e "${GREEN}خروجی:${NC}"
        eval "$2" 2>/dev/null || echo "  (اجرا شد)"
    fi
    echo ""
}

# ============================================
# بخش 1: Parameter Expansion (گسترش پارامترها)
# ============================================

show_section "🔧 بخش 1: Parameter Expansion - دستکاری رشته‌ها"

echo -e "${GREEN}Parameter Expansion چیست؟${NC}"
echo "روش‌های قدرتمند برای دستکاری و استخراج اطلاعات از متغیرها"
echo ""

# ========== سطح مبتدی ==========
show_section "📚 سطح مبتدی - Parameter Expansion"

show_example "1. حذف از ابتدا (کوتاه‌ترین)" "var='123ali123'; echo \${var#*123}"
var='123ali123'
echo "  ${var#*123}"
echo ""

show_example "2. حذف از ابتدا (بلندترین)" "var='123ali123'; echo \${var##*123}"
var='123ali123'
echo "  ${var##*123}"
echo ""

show_example "3. حذف از انتها (کوتاه‌ترین)" "var='123ali123'; echo \${var%123*}"
var='123ali123'
echo "  ${var%123*}"
echo ""

show_example "4. حذف از انتها (بلندترین)" "var='123ali123'; echo \${var%%123*}"
var='123ali123'
echo "  ${var%%123*}"
echo ""

show_example "5. جایگزینی (اولین مورد)" "var='hello world hello'; echo \${var/hello/hi}"
var='hello world hello'
echo "  ${var/hello/hi}"
echo ""

show_example "6. جایگزینی (همه موارد)" "var='hello world hello'; echo \${var//hello/hi}"
var='hello world hello'
echo "  ${var//hello/hi}"
echo ""

# ========== سطح متوسط ==========
show_section "📖 سطح متوسط - Parameter Expansion"

show_example "7. مقدار پیش‌فرض (اگر خالی)" "unset name; echo \${name:-'کاربر ناشناس'}"
unset name 2>/dev/null
echo "  ${name:-'کاربر ناشناس'}"
echo ""

show_example "8. مقدار پیش‌فرض و تنظیم" "unset name; result=\${name:=Ali}; echo \$name"
unset name 2>/dev/null
result=${name:=Ali}
echo "  name = $name"
echo ""

show_example "9. مقدار جایگزین (اگر مقدار دارد)" "name='Ali'; echo \${name:+'سلام '}\${name}"
name='Ali'
echo "  ${name:+'سلام '}${name}"
echo ""

show_example "10. برش رشته (substring)" "text='Hello World'; echo \${text:6:5}"
text='Hello World'
echo "  ${text:6:5}"
echo ""

show_example "11. طول رشته" "text='Hello'; echo \${#text}"
text='Hello'
echo "  ${#text}"
echo ""

show_example "12. تبدیل به حروف بزرگ" "name='ali'; echo \${name^^}"
name='ali'
echo "  ${name^^}"
echo ""

show_example "13. تبدیل به حروف کوچک" "name='ALI'; echo \${name,,}"
name='ALI'
echo "  ${name,,}"
echo ""

# ========== سطح پیشرفته ==========
show_section "🚀 سطح پیشرفته - Parameter Expansion"

show_example "14. تبدیل اولین حرف به بزرگ" "name='ali'; echo \${name^}"
name='ali'
echo "  ${name^}"
echo ""

show_example "15. نام متغیر غیرمستقیم" "name='Ali'; var='name'; echo \${!var}"
name='Ali'
var='name'
echo "  ${!var}"
echo ""

show_example "16. حذف الگو از ابتدا" "path='/home/user/file.txt'; echo \${path#/}"
path='/home/user/file.txt'
echo "  ${path#/}"
echo ""

show_example "17. استخراج نام فایل" "path='/home/user/file.txt'; echo \${path##*/}"
path='/home/user/file.txt'
echo "  ${path##*/}"
echo ""

show_example "18. استخراج مسیر دایرکتوری" "path='/home/user/file.txt'; echo \${path%/*}"
path='/home/user/file.txt'
echo "  ${path%/*}"
echo ""

show_example "19. استخراج پسوند فایل" "file='document.pdf'; echo \${file##*.}"
file='document.pdf'
echo "  ${file##*.}"
echo ""

# ============================================
# بخش 2: توابع پیشرفته
# ============================================

show_section "⚙️ بخش 2: توابع پیشرفته در Bash"

echo -e "${GREEN}توابع چیست؟${NC}"
echo "بلوک‌های کد قابل استفاده مجدد که می‌توانند آرگومان بگیرند و مقدار برگردانند"
echo ""

# ========== سطح مبتدی ==========
show_section "📚 سطح مبتدی - توابع"

echo -e "${YELLOW}مثال 1: تابع ساده${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'FUNC1'
greet() {
    echo "سلام $1"
}
greet "علی"
FUNC1
echo -e "${GREEN}خروجی:${NC}"
greet() {
    echo "  سلام $1"
}
greet "علی"
echo ""

echo -e "${YELLOW}مثال 2: تابع با چند آرگومان${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'FUNC2'
calculate() {
    local num1=$1
    local num2=$2
    echo $((num1 + num2))
}
result=$(calculate 10 20)
echo "نتیجه: $result"
FUNC2
echo -e "${GREEN}خروجی:${NC}"
calculate() {
    local num1=$1
    local num2=$2
    echo $((num1 + num2))
}
result=$(calculate 10 20)
echo "  نتیجه: $result"
echo ""

# ========== سطح متوسط ==========
show_section "📖 سطح متوسط - توابع"

echo -e "${YELLOW}مثال 3: بازگشت مقدار با return${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'FUNC3'
check_age() {
    local age=$1
    if [ $age -ge 18 ]; then
        return 0  # موفق
    else
        return 1  # ناموفق
    fi
}
check_age 20 && echo "بزرگسال" || echo "کودک"
FUNC3
echo -e "${GREEN}خروجی:${NC}"
check_age() {
    local age=$1
    if [ $age -ge 18 ]; then
        return 0
    else
        return 1
    fi
}
check_age 20 && echo "  بزرگسال" || echo "  کودک"
echo ""

echo -e "${YELLOW}مثال 4: تابع با آرگومان‌های نامحدود${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'FUNC4'
sum_all() {
    local total=0
    for num in "$@"; do
        total=$((total + num))
    done
    echo $total
}
sum_all 1 2 3 4 5
FUNC4
echo -e "${GREEN}خروجی:${NC}"
sum_all() {
    local total=0
    for num in "$@"; do
        total=$((total + num))
    done
    echo $total
}
echo "  $(sum_all 1 2 3 4 5)"
echo ""

echo -e "${YELLOW}مثال 5: تابع بازگشتی${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'FUNC5'
factorial() {
    local n=$1
    if [ $n -le 1 ]; then
        echo 1
    else
        local prev=$(factorial $((n - 1)))
        echo $((n * prev))
    fi
}
factorial 5
FUNC5
echo -e "${GREEN}خروجی:${NC}"
factorial() {
    local n=$1
    if [ $n -le 1 ]; then
        echo 1
    else
        local prev=$(factorial $((n - 1)))
        echo $((n * prev))
    fi
}
echo "  $(factorial 5)"
echo ""

# ========== سطح پیشرفته ==========
show_section "🚀 سطح پیشرفته - توابع"

echo -e "${YELLOW}مثال 6: تابع با export${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'FUNC6'
# در یک فایل
export -f my_function

# در فایل دیگر می‌توان استفاده کرد
FUNC6
echo "  توابع export شده در اسکریپت‌های فرزند قابل استفاده هستند"
echo ""

echo -e "${YELLOW}مثال 7: تابع به عنوان دستور${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'FUNC7'
alias ll='ls -lah'
# یا
ll() {
    ls -lah "$@"
}
FUNC7
echo "  توابع می‌توانند جایگزین دستورات شوند"
echo ""

# ============================================
# بخش 3: آرایه‌ها (Arrays)
# ============================================

show_section "📦 بخش 3: آرایه‌ها در Bash"

echo -e "${GREEN}آرایه چیست؟${NC}"
echo "مجموعه‌ای از مقادیر که با اندیس قابل دسترسی هستند"
echo ""

# ========== سطح مبتدی ==========
show_section "📚 سطح مبتدی - آرایه‌ها"

echo -e "${YELLOW}مثال 1: آرایه ساده${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR1'
fruits=("سیب" "موز" "پرتقال")
echo ${fruits[0]}
echo ${fruits[1]}
echo ${fruits[2]}
ARR1
echo -e "${GREEN}خروجی:${NC}"
fruits=("سیب" "موز" "پرتقال")
echo "  ${fruits[0]}"
echo "  ${fruits[1]}"
echo "  ${fruits[2]}"
echo ""

echo -e "${YELLOW}مثال 2: تمام عناصر${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR2'
fruits=("سیب" "موز" "پرتقال")
echo "همه: ${fruits[@]}"
echo "تعداد: ${#fruits[@]}"
ARR2
echo -e "${GREEN}خروجی:${NC}"
fruits=("سیب" "موز" "پرتقال")
echo "  همه: ${fruits[@]}"
echo "  تعداد: ${#fruits[@]}"
echo ""

echo -e "${YELLOW}مثال 3: حلقه روی آرایه${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR3'
fruits=("سیب" "موز" "پرتقال")
for fruit in "${fruits[@]}"; do
    echo "میوه: $fruit"
done
ARR3
echo -e "${GREEN}خروجی:${NC}"
fruits=("سیب" "موز" "پرتقال")
for fruit in "${fruits[@]}"; do
    echo "  میوه: $fruit"
done
echo ""

# ========== سطح متوسط ==========
show_section "📖 سطح متوسط - آرایه‌ها"

echo -e "${YELLOW}مثال 4: اضافه کردن به آرایه${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR4'
fruits=("سیب" "موز")
fruits+=("پرتقال")
fruits[3]="انگور"
echo ${fruits[@]}
ARR4
echo -e "${GREEN}خروجی:${NC}"
fruits=("سیب" "موز")
fruits+=("پرتقال")
fruits[3]="انگور"
echo "  ${fruits[@]}"
echo ""

echo -e "${YELLOW}مثال 5: حذف از آرایه${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR5'
fruits=("سیب" "موز" "پرتقال")
unset fruits[1]
echo ${fruits[@]}
ARR5
echo -e "${GREEN}خروجی:${NC}"
fruits=("سیب" "موز" "پرتقال")
unset fruits[1]
echo "  ${fruits[@]}"
echo ""

echo -e "${YELLOW}مثال 6: آرایه Associative (دیکشنری)${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR6'
declare -A person
person[name]="علی"
person[age]=25
person[city]="تهران"
echo "نام: ${person[name]}"
echo "سن: ${person[age]}"
echo "شهر: ${person[city]}"
ARR6
echo -e "${GREEN}خروجی:${NC}"
declare -A person
person[name]="علی"
person[age]=25
person[city]="تهران"
echo "  نام: ${person[name]}"
echo "  سن: ${person[age]}"
echo "  شهر: ${person[city]}"
echo ""

# ========== سطح پیشرفته ==========
show_section "🚀 سطح پیشرفته - آرایه‌ها"

echo -e "${YELLOW}مثال 7: اندیس‌های آرایه${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR7'
fruits=("سیب" "موز" "پرتقال")
echo "اندیس‌ها: ${!fruits[@]}"
for i in "${!fruits[@]}"; do
    echo "$i: ${fruits[$i]}"
done
ARR7
echo -e "${GREEN}خروجی:${NC}"
fruits=("سیب" "موز" "پرتقال")
for i in "${!fruits[@]}"; do
    echo "  $i: ${fruits[$i]}"
done
echo ""

echo -e "${YELLOW}مثال 8: برش آرایه${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'ARR8'
numbers=(1 2 3 4 5 6 7 8 9 10)
echo "3 عنصر اول: ${numbers[@]:0:3}"
echo "از اندیس 5: ${numbers[@]:5}"
ARR8
echo -e "${GREEN}خروجی:${NC}"
numbers=(1 2 3 4 5 6 7 8 9 10)
echo "  3 عنصر اول: ${numbers[@]:0:3}"
echo "  از اندیس 5: ${numbers[@]:5}"
echo ""

# ============================================
# بخش 4: I/O Redirection (تغییر مسیر ورودی/خروجی)
# ============================================

show_section "🔄 بخش 4: I/O Redirection"

echo -e "${GREEN}Redirection چیست؟${NC}"
echo "تغییر مسیر ورودی و خروجی دستورات"
echo ""

# ========== سطح مبتدی ==========
show_section "📚 سطح مبتدی - Redirection"

show_example "1. ذخیره خروجی در فایل" "echo 'سلام دنیا' > output.txt && cat output.txt"
echo 'سلام دنیا' > output.txt
cat output.txt
rm -f output.txt
echo ""

show_example "2. افزودن به فایل" "echo 'خط 1' > file.txt && echo 'خط 2' >> file.txt && cat file.txt"
echo 'خط 1' > file.txt
echo 'خط 2' >> file.txt
cat file.txt
rm -f file.txt
echo ""

show_example "3. خواندن از فایل" "echo 'محتوای فایل' > input.txt && cat < input.txt"
echo 'محتوای فایل' > input.txt
cat < input.txt
rm -f input.txt
echo ""

show_example "4. Pipe (لوله)" "echo 'Hello World' | grep 'World'"
echo 'Hello World' | grep 'World'
echo ""

# ========== سطح متوسط ==========
show_section "📖 سطح متوسط - Redirection"

show_example "5. تغییر مسیر خطا" "ls /nonexistent 2> error.txt && cat error.txt"
ls /nonexistent 2> error.txt 2>/dev/null || echo "خطا ذخیره شد"
cat error.txt 2>/dev/null || echo "  (فایل خطا ایجاد شد)"
rm -f error.txt
echo ""

show_example "6. تغییر مسیر خروجی و خطا" "ls /nonexistent &> all_output.txt"
ls /nonexistent &> all_output.txt 2>/dev/null || echo "  خروجی و خطا ذخیره شد"
rm -f all_output.txt
echo ""

show_example "7. Here Document" "cat << EOF
خط اول
خط دوم
خط سوم
EOF"
cat << EOF
  خط اول
  خط دوم
  خط سوم
EOF
echo ""

show_example "8. Here String" "grep 'World' <<< 'Hello World'"
grep 'World' <<< 'Hello World'
echo ""

# ========== سطح پیشرفته ==========
show_section "🚀 سطح پیشرفته - Redirection"

show_example "9. Process Substitution" "diff <(echo 'خط 1') <(echo 'خط 2')"
diff <(echo 'خط 1') <(echo 'خط 2') 2>/dev/null || echo "  تفاوت نمایش داده شد"
echo ""

show_example "10. تغییر مسیر به /dev/null" "echo 'این نمایش داده نمی‌شود' > /dev/null && echo 'انجام شد'"
echo 'این نمایش داده نمی‌شود' > /dev/null && echo "  انجام شد"
echo ""

show_example "11. ترکیب stdout و stderr" "ls /nonexistent 2>&1 | grep 'error'"
ls /nonexistent 2>&1 | grep -i 'error' || echo "  خطا به stdout هدایت شد"
echo ""

# ============================================
# بخش 5: Brace Expansion و Arithmetic
# ============================================

show_section "🔢 بخش 5: Brace Expansion و Arithmetic"

# ========== سطح مبتدی ==========
show_section "📚 سطح مبتدی - Brace Expansion"

show_example "1. تولید اعداد" "echo {1..5}"
echo {1..5}
echo ""

show_example "2. تولید حروف" "echo {a..e}"
echo {a..e}
echo ""

show_example "3. چند مقدار" "echo file{1,2,3}.txt"
echo file{1,2,3}.txt
echo ""

# ========== سطح متوسط ==========
show_section "📖 سطح متوسط - Brace Expansion"

show_example "4. با فاصله" "echo {1..10..2}"
echo {1..10..2}
echo ""

show_example "5. ترکیب" "echo {a,b}{1,2}"
echo {a,b}{1,2}
echo ""

show_example "6. Arithmetic Expansion" "echo \$((10 + 20))"
echo $((10 + 20))
echo ""

show_example "7. محاسبات پیچیده" "echo \$(( (10 + 5) * 2 ))"
echo $(( (10 + 5) * 2 ))
echo ""

# ========== سطح پیشرفته ==========
show_section "🚀 سطح پیشرفته - Arithmetic"

show_example "8. متغیر در محاسبات" "x=10; y=20; echo \$((x * y))"
x=10; y=20; echo $((x * y))
echo ""

show_example "9. عملگرهای بیتی" "echo \$((5 & 3))"
echo $((5 & 3))
echo ""

show_example "10. افزایش/کاهش" "x=5; ((x++)); echo \$x"
x=5; ((x++)); echo $x
echo ""

# ============================================
# بخش 6: Background Jobs و Job Control
# ============================================

show_section "⚡ بخش 6: Background Jobs و Job Control"

echo -e "${GREEN}Background Jobs چیست؟${NC}"
echo "اجرای دستورات در پس‌زمینه و مدیریت آن‌ها"
echo ""

# ========== سطح مبتدی ==========
show_section "📚 سطح مبتدی - Background Jobs"

echo -e "${YELLOW}مثال 1: اجرای دستور در پس‌زمینه${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'JOB1'
sleep 5 &
echo "Job در پس‌زمینه اجرا شد"
jobs
JOB1
echo -e "${GREEN}خروجی:${NC}"
sleep 2 &
echo "  Job در پس‌زمینه اجرا شد"
sleep 0.5
jobs
wait
echo ""

echo -e "${YELLOW}مثال 2: مشاهده Jobs${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'JOB2'
sleep 10 &
sleep 5 &
jobs -l  # نمایش PID
JOB2
echo "  jobs -l: نمایش لیست jobs با PID"
echo ""

# ========== سطح متوسط ==========
show_section "📖 سطح متوسط - Job Control"

echo -e "${YELLOW}مثال 3: آوردن Job به پیش‌زمینه${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'JOB3'
sleep 10 &
fg %1  # آوردن job شماره 1 به پیش‌زمینه
JOB3
echo "  fg: آوردن job به پیش‌زمینه"
echo ""

echo -e "${YELLOW}مثال 4: متوقف کردن Job${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'JOB4'
sleep 10 &
kill %1  # متوقف کردن job شماره 1
JOB4
echo "  kill %1: متوقف کردن job"
echo ""

# ========== سطح پیشرفته ==========
show_section "🚀 سطح پیشرفته - Job Control"

echo -e "${YELLOW}مثال 5: nohup${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'JOB5'
nohup long_script.sh &
# اجرا حتی بعد از بستن ترمینال ادامه می‌یابد
JOB5
echo "  nohup: اجرای دستور حتی بعد از بستن ترمینال"
echo ""

echo -e "${YELLOW}مثال 6: disown${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'JOB6'
sleep 100 &
disown
# job از لیست jobs حذف می‌شود اما ادامه می‌یابد
JOB6
echo "  disown: جدا کردن job از shell"
echo ""

# ============================================
# بخش 7: Traps و Signal Handling
# ============================================

show_section "🛡️ بخش 7: Traps و Signal Handling"

echo -e "${GREEN}Trap چیست؟${NC}"
echo "مدیریت سیگنال‌ها و اجرای کد هنگام وقوع رویدادها"
echo ""

echo -e "${YELLOW}مثال 1: Trap برای EXIT${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'TRAP1'
cleanup() {
    echo "پاکسازی انجام می‌شود..."
    rm -f temp_file.txt
}
trap cleanup EXIT
echo "test" > temp_file.txt
echo "فایل ایجاد شد"
exit 0
TRAP1
echo -e "${GREEN}خروجی:${NC}"
cleanup() {
    echo "  پاکسازی انجام می‌شود..."
    rm -f temp_file.txt 2>/dev/null
}
trap cleanup EXIT
echo "test" > temp_file.txt
echo "  فایل ایجاد شد"
echo ""

echo -e "${YELLOW}مثال 2: Trap برای SIGINT (Ctrl+C)${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'TRAP2'
interrupt_handler() {
    echo "عملیات متوقف شد!"
    exit 1
}
trap interrupt_handler SIGINT
echo "برای توقف Ctrl+C بزنید..."
sleep 5
TRAP2
echo "  trap SIGINT: مدیریت Ctrl+C"
echo ""

# ============================================
# بخش 8: دستورات مفید Linux
# ============================================

show_section "🐧 بخش 8: دستورات مفید Linux"

# ========== find و xargs ==========
show_section "📂 find و xargs"

show_example "1. جستجوی فایل" "find . -name '*.txt' -type f 2>/dev/null | head -3"
find . -name '*.txt' -type f 2>/dev/null | head -3
echo ""

show_example "2. جستجو با xargs" "echo 'file1.txt file2.txt' | xargs ls"
echo 'file1.txt file2.txt' | xargs ls 2>/dev/null || echo "  xargs: اجرای دستور برای هر ورودی"
echo ""

show_example "3. جستجو و حذف" "find . -name '*.tmp' -delete"
echo "  find ... -delete: حذف فایل‌های پیدا شده"
echo ""

# ========== tar و فشرده‌سازی ==========
show_section "📦 tar و فشرده‌سازی"

show_example "4. ایجاد آرشیو" "tar -czf archive.tar.gz *.sh 2>/dev/null && ls -lh archive.tar.gz 2>/dev/null || echo 'آرشیو ایجاد شد'"
tar -czf archive.tar.gz *.sh 2>/dev/null
ls -lh archive.tar.gz 2>/dev/null || echo "  آرشیو ایجاد شد"
rm -f archive.tar.gz
echo ""

show_example "5. استخراج آرشیو" "tar -xzf archive.tar.gz"
echo "  tar -xzf: استخراج آرشیو"
echo ""

# ========== Permissions ==========
show_section "🔐 Permissions"

show_example "6. تغییر دسترسی" "chmod +x script.sh"
echo "  chmod +x: افزودن مجوز اجرا"
echo ""
chmod $r$w$x script.sh
show_example "7. مشاهده دسترسی‌ها" "ls -l *.sh 2>/dev/null | head -2"
ls -l *.sh 2>/dev/null | head -2 || echo "  ls -l: نمایش دسترسی‌ها"
echo ""

# ========== Process Management ==========
show_section "⚙️ Process Management"

show_example "8. مشاهده پردازش‌ها" "ps aux | head -3"
ps aux 2>/dev/null | head -3 || echo "  ps aux: لیست پردازش‌ها"
echo ""

show_example "9. جستجوی پردازش" "ps aux | grep bash | head -2"
ps aux 2>/dev/null | grep -i bash | head -2 || echo "  ps aux | grep: جستجوی پردازش"
echo ""

# ========== Network Commands ==========
show_section "🌐 Network Commands"

show_example "10. دانلود فایل" "curl -I https://www.google.com 2>/dev/null | head -1"
curl -I https://www.google.com 2>/dev/null | head -1 || echo "  curl: دانلود/ارسال درخواست HTTP"
echo ""

show_example "11. تست اتصال" "ping -c 2 8.8.8.8 2>/dev/null | head -3"
ping -c 2 8.8.8.8 2>/dev/null | head -3 || echo "  ping: تست اتصال شبکه"
echo ""

# ========== System Info ==========
show_section "💻 System Info"

show_example "12. فضای دیسک" "df -h 2>/dev/null | head -3"
df -h 2>/dev/null | head -3 || echo "  df -h: نمایش فضای دیسک"
echo ""

show_example "13. استفاده از دیسک" "du -sh . 2>/dev/null"
du -sh . 2>/dev/null || echo "  du -sh: اندازه دایرکتوری"
echo ""

# ============================================
# بخش 9: دستورات پردازش متن
# ============================================

show_section "📝 بخش 9: دستورات پردازش متن"

show_example "1. cut - برش ستون" "echo 'Ali:25:Developer' | cut -d: -f1,2"
echo 'Ali:25:Developer' | cut -d: -f1,2
echo ""

show_example "2. tr - تبدیل کاراکتر" "echo 'Hello World' | tr '[:lower:]' '[:upper:]'"
echo 'Hello World' | tr '[:lower:]' '[:upper:]'
echo ""

show_example "3. sort - مرتب‌سازی" "echo -e 'c\nb\na' | sort"
echo -e 'c\nb\na' | sort
echo ""

show_example "4. uniq - حذف تکراری" "echo -e 'a\na\nb\nb' | sort | uniq"
echo -e 'a\na\nb\nb' | sort | uniq
echo ""

show_example "5. wc - شمارش" "echo -e 'خط 1\nخط 2\nخط 3' | wc -l"
echo -e 'خط 1\nخط 2\nخط 3' | wc -l
echo ""

# ============================================
# بخش 10: Debugging و Best Practices
# ============================================

show_section "🐛 بخش 10: Debugging و Best Practices"

echo -e "${GREEN}Debugging چیست؟${NC}"
echo "روش‌های عیب‌یابی و نوشتن کد بهتر"
echo ""

echo -e "${YELLOW}مثال 1: set -x (نمایش دستورات)${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'DEBUG1'
set -x
name="Ali"
echo "Hello $name"
set +x
DEBUG1
echo -e "${GREEN}خروجی:${NC}"
set -x
name="Ali"
echo "Hello $name"
set +x
echo ""

echo -e "${YELLOW}مثال 2: set -e (توقف در خطا)${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'DEBUG2'
set -e
false  # این خطا ایجاد می‌کند
echo "این اجرا نمی‌شود"
DEBUG2
echo "  set -e: توقف اسکریپت در صورت خطا"
echo ""

echo -e "${YELLOW}مثال 3: set -u (خطا برای متغیر تعریف نشده)${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'DEBUG3'
set -u
echo $undefined_var  # خطا می‌دهد
DEBUG3
echo "  set -u: خطا برای متغیرهای تعریف نشده"
echo ""

echo -e "${YELLOW}مثال 4: set -o pipefail${NC}"
echo -e "${BLUE}کد:${NC}"
cat << 'DEBUG4'
set -o pipefail
false | true  # exit code غیر صفر
echo $?
DEBUG4
echo "  set -o pipefail: خطا در pipe باعث خطای اسکریپت می‌شود"
echo ""

# ============================================
# بخش 11: Environment Variables
# ============================================

show_section "🌍 بخش 11: Environment Variables"

echo -e "${GREEN}Environment Variables چیست؟${NC}"
echo "متغیرهای محیطی که در تمام shell‌ها قابل دسترسی هستند"
echo ""

show_example "1. مشاهده متغیر محیطی" "echo \$HOME"
echo $HOME
echo ""

show_example "2. تنظیم متغیر محیطی" "export MY_VAR='test' && echo \$MY_VAR"
export MY_VAR='test'
echo $MY_VAR
unset MY_VAR
echo ""

show_example "3. PATH" "echo \$PATH | tr ':' '\n' | head -3"
echo $PATH | tr ':' '\n' | head -3
echo ""

show_example "4. متغیرهای مهم" "echo 'USER:' \$USER; echo 'SHELL:' \$SHELL; echo 'PWD:' \$PWD"
echo "USER: $USER"
echo "SHELL: $SHELL"
echo "PWD: $PWD"
echo ""

# ============================================
# خلاصه و نکات مهم
# ============================================

show_section "📝 خلاصه و نکات مهم"

echo -e "${GREEN}💡 نکات طلایی Parameter Expansion:${NC}"
echo "• \${var#pattern}: حذف کوتاه‌ترین الگو از ابتدا"
echo "• \${var##pattern}: حذف بلندترین الگو از ابتدا"
echo "• \${var%pattern}: حذف کوتاه‌ترین الگو از انتها"
echo "• \${var%%pattern}: حذف بلندترین الگو از انتها"
echo "• \${var/old/new}: جایگزینی اولین مورد"
echo "• \${var//old/new}: جایگزینی همه موارد"
echo "• \${var:-default}: مقدار پیش‌فرض"
echo "• \${var:offset:length}: برش رشته"
echo ""

echo -e "${GREEN}💡 نکات طلایی توابع:${NC}"
echo "• از local برای متغیرهای محلی استفاده کنید"
echo "• return برای کد خروجی، echo برای مقدار"
echo "• \$@ برای تمام آرگومان‌ها"
echo "• export -f برای استفاده در shell‌های فرزند"
echo ""

echo -e "${GREEN}💡 نکات طلایی آرایه‌ها:${NC}"
echo "• \${array[@]}: تمام عناصر"
echo "• \${#array[@]}: تعداد عناصر"
echo "• \${!array[@]}: اندیس‌ها"
echo "• declare -A برای آرایه‌های associative"
echo ""

echo -e "${GREEN}💡 نکات طلایی Redirection:${NC}"
echo "• >: نوشتن در فایل (بازنویسی)"
echo "• >>: افزودن به فایل"
echo "• <: خواندن از فایل"
echo "• 2>: تغییر مسیر خطا"
echo "• &>: تغییر مسیر خروجی و خطا"
echo "• |: pipe (لوله)"
echo "• <<: Here Document"
echo "• <<<: Here String"
echo ""

echo -e "${GREEN}💡 نکات طلایی Debugging:${NC}"
echo "• set -x: نمایش دستورات"
echo "• set -e: توقف در خطا"
echo "• set -u: خطا برای متغیر تعریف نشده"
echo "• set -o pipefail: خطا در pipe"
echo "• ترکیب: set -euo pipefail"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}🎉 آموزش به پایان رسید!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "برای اجرای این آموزش:"
echo "  bash مباحث_پیشرفته_بش_و_لینوکس.sh"
echo ""

