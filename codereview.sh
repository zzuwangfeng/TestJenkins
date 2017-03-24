## 检查 Git 是否存在
git=$(which git)
[[ -x "$git" ]] || { printf "\e[1;31mGit Not Found,  \"brew install git\"...\e[0m\n";exit 1; }

## 检查 OCLint 是否存在
lint=$(which /usr/local/bin/oclint) 
[[ -x "$lint" ]] || { printf "\e[1;31mOCLint Not Found, use \"brew tap oclint/formulae && brew install oclint\" to install\e[0m\n"; exit 1; }

## 获取当前分支

branch=$(git rev-parse --abbrev-ref HEAD)
echo "Current Branch: $branch"

## 在本分支修改的文件
 files=$(git diff --name-only dev $(git merge-base dev master) | grep '^[^(Pods/)].*\.m$')

## 在本分支新增的文件(Pods 除外)
#files=$(git diff --name-only --diff-filter=A master $branch | grep '^[^(Pods/)].*\.[mh]$')
[[ -n "$files" ]] || { printf "没有新增文件\n"; exit 0; }
commnadFiles=""
echo "\nAnalized Files:\n--------------------------------"
for file in $files; do
    if [[ -f $file ]]; then
        echo $file
        commnadFiles=" $commnadFiles $file"
    fi
done
echo "--------------------------------\n"

## 输出类型，默认 html
type=$1
[[ -n $1 ]] || type='html'
echo "Report Type: $type"

report_file_o="./report_result.$type"
#xcodebuild |xcpretty -r json-compilation-database
xcodebuild clean
xcodebuild | xcpretty -r json-compilation-database
cp build/reports/compilation_db.json compile_commands.json
/usr/local/bin/oclint-json-compilation-database -e Pods   -- -rc=LONG_LINE=200 -rc=NCSS_METHOD=100  -o=report.html
#/usr/local/bin/oclint-json-compilation-database -e Pods -- -o=report.html -- -x objective-c -std=gnu99 -fobjc-arc
#/usr/local/bin/oclint $commnadFiles -report-type $type -R ./rules -o $report_file_o \
#-rc LONG_METHOD=50 \
#-rc TOO_MANY_PARAMETERS=8 \
#-- -x objective-c -std=gnu99 -fobjc-arc

if [ $? -eq 0 ]; then
    printf "报告生成成功！\n"
else
    printf "报告生成失败\n"
    exit 1
fi
