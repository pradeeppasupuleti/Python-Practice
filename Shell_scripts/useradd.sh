#!/bin/ksh


USRADM=/usr/local/goes/usradm/bau
USRADM_TOOLS=/usr/local/goes/usradm/tools

# Basic
password_reset=${USRADM}/passwd_m.pl
mypassword_reset=${USRADM}/mypasswd_m.pl
non_expiry_password_set=${USRADM}/non_expiry_m.pl
unlock_user=${USRADM}/unlock_m.pl
useradd=${USRADM}/useradd_m.pl
useradd_s=${USRADM}/useradd_m2.pl
useradd_m3=${USRADM}/useradd_m3.pl
#useradd_test=${USRADM}/test_useradd_m.pl
group_add=${USRADM}/groupadd_m.pl
cclogin=${USRADM}/Addconcurrent_m.pl
acc_test=${USRADM}/test_access_m.pl
fix_prompt=${USRADM}/fixprompt_m.pl
add_sudo=${USRADM}/addsudo_m.pl
del_sudo=${USRADM}/delsudo_m.pl
del_sudo_all=${USRADM}/delsudo_all_m.pl
run_command_remotely=${USRADM}/remote_command.pl
addto_sec_group=${USRADM}/addto_sec_group_m.pl
userdel=${USRADM}/userdel_m.pl

# Advanced
remote_run=${USRADM}/remote_run_m.pl
csv_password_reset=${USRADM}/password_update_csv_m.pl
non_personal_id_reprot=${USRADM}/sr_oracle_report_m.pl
test_noper_id=${USRADM}/test_non_personal_id_m.pl
addsudo_file=${USRADM}/addsudo_file_m.pl
delsudo_file=${USRADM}/delsudo_file_m.pl
useradd_useradminops=${USRADM}/useradd_useradminops_m.pl

# Reval
audit_get_pw=${USRADM}/audit_get_pw_m.pl
audit_get_pw_gr_sudo=${USRADM}/audit_get_pw_gr_sudo_m.pl
csv_userdel=${USRADM}/csv_userdel_m.pl
csv_usermod=${USRADM}/csv_usermod_m.pl
lock_account=${USRADM}/linux_lock_m.pl
delete_locked_account=${USRADM}/delete_lock_account_m.pl

# CSV
csv_grep=${USRADM}/csv_grep_m.pl
csv_del_sudo_alias=${USRADM}/csv_del_sudo_alias_m.pl
csv_command=${USRADM}/csv_command_m.pl

# Tool

non_personal_id_db=$USRADM_TOOLS/non_personal_id_db.pl

# Root Password Maintaining
password_generator=$USRADM_TOOLS/password_generator.pl
shadow_generator=$USRADM_TOOLS/linux_shadow.pl
csv_update_root_password=${USRADM}/csv_update_root_password_m.pl


#trap "stty echo" 1 9 15

mainmenu() {
   printf "\nUser Admin Menu (New:LXAPP0424)\n"
   printf "*************************************\n"
   printf   "\n"
   printf       "B.  Basic Menu\n"
   printf       "A.  Advanced Menu\n"
   printf       "C.  CSV Menu\n"
   printf       "R.  Reval Menu\n"
   printf       "T.  Tool Menu\n"
   printf   "P.  Root Passwd Menu\n"

   printf   "\n"
   printf       "X.  EXIT\n\n"

   read MAINQ?"Choose the option: "
   case "$MAINQ" in
   B|b)  basic_menu;;
   A|a)  advanced_menu;;
   C|c)  csv_menu;;
   R|r)  reval_menu;;
   T|t)  tools_menu;;
   P|p)  root_password_menu;;
   x|X)  exit;;
   *)           mainmenu ;;
   esac
   mainmenu
}

basic_menu() {
   printf "\nUser Admin Menu Basic(Multi-Proccesses: 10)\n"
   printf "*************************************\n"
   printf   "\n"
   printf       "P.  Password Reset                           (Perl, SSH or Telnet)\n"
   printf       "PM. Password Reset, My Password              (Perl, SSH or Telnet)\n"
   printf       "N.  Non-expiry Password Set                  (Perl, SSH or Telnet)\n"
   printf       "U.  User(s) Unlock                           (Perl, SSH or Telnet)\n"
   printf       "A.  User(s) Add                              (Perl, SSH or Telnet)\n"
   printf       "AP. User(s) Add + pw reset and non-expiry    (Perl, SSH or Telnet)\n"
   printf       "D.  User(s) Del                              (Perl, SSH or Telnet)\n"
   printf       "C.  Concurrent Login Add                     (Perl, SSH or Telnet)\n"
   printf       "G.  Group Add                                (Perl, SSH or Telnet)\n"
   printf   "Gs. Set Secondary Groups for User(s)         (Perl, SSH or Telnet)\n"
   printf       "T.  Test System Access + sudo                (Perl, SSH or Telnet)\n"
   printf       "F.  Fix My Prompt                            (Perl, SSH or Telnet)\n"
   printf       "S.  Sudoers - Add User(s)                    (Perl, SSH or Telnet)\n"
   printf       "SD. Sudoers - Remove User(s) from a group    (Perl, SSH or Telnet)\n"
   printf       "SA. Sudoers - Remove User(s) completely      (Perl, SSH or Telnet)\n"
   printf       "Z.  Run commands on remote system            (Perl, SSH or Telnet)\n"
   printf   "\n"
   printf       "X.  EXIT\n\n"

   read MAINQ?"Choose the option: "
   case "$MAINQ" in
   P|p)  $password_reset;;
   PM|Pm|pm)  $mypassword_reset;;
   N|n)  $non_expiry_password_set;;
   U|u)  $unlock_user;;
   A|a)  $useradd_s;;
   AP|Ap|ap) $useradd_m3;;
   D|d)  $userdel;;
   C|c)  $cclogin;;
   G|g)  $group_add;;
   Gs|GS|gs)  $addto_sec_group;;
   T|t)  $acc_test;;
   F|f)  $fix_prompt;;
   S|s)  $add_sudo;;
   SD|Sd|sd)  $del_sudo;;
   SA|Sa|sa)  $del_sudo_all;;
   Z|z)  $run_command_remotely;;

   x|X)  mainmenu;;
   *)           basic_menu ;;
   esac
   basic_menu
}


advanced_menu() {
   printf "\nUser Admin Menu Advanced(Multi-Proccesses: 10)\n"
   printf "*************************************\n"
   printf   "\n"
   printf       "R.  Remote Run Script                           (Perl, SSH or Telnet)\n"
   printf       "TN. Test Non_personal_ID Access                 (Perl, SSH or Telnet)\n"
   printf       "RN. Report Tool for non_personalID              (Perl, SSH or Telnet)\n"
   printf       "CP. CSV Password Reset                          (Perl, SSH or Telnet)\n"
   printf       "SA. Sudoers - Add User_Alias&Cmnd_Alias         (Perl, SSH or Telnet)\n"
   printf       "SD. Sudoers - Del User_Alias&Cmnd_Alias         (Perl, SSH or Telnet)\n"
   printf       "UA. Useradd (OQA only-> Add all user admin ops) (Perl, SSH or Telnet)\n"
   printf   "\n"
   printf       "X.  EXIT\n\n"

   read MAINQ?"Choose the option: "
   case "$MAINQ" in
   R|r)  $remote_run;;
   TN|Tn|tn)  $test_noper_id;;
   RN|Rn|rn)  $non_personal_id_reprot;;
   CP|Cp|cp)  $csv_password_reset;;
   SA|Sa|sa)  $addsudo_file;;
   SD|Sd|sd)  $delsudo_file;;
   UA|Ua|ua)  $useradd_useradminops;;

   x|X)  mainmenu;;
   *)           advanced_menu ;;
   esac
   advanced_menu
}

reval_menu() {
   printf "\nUser Admin Menu Advanced(Multi-Proccesses: 10)\n"
   printf "*************************************\n"
   printf   "\n"
   printf       "L.  Lock Account(s)                             (Perl, SSH or Telnet)\n"
   printf       "RL. Remove Locked Account(s)                    (Perl, SSH or Telnet)\n"
   printf       "G.  Extract passwd into a local file            (Perl, SSH or Telnet)\n"
   printf       "GA. Extract passwd group sudoers into a folder  (Perl, SSH or Telnet)\n"
   printf       "CD. CSV - User(s) del                           (Perl, SSH or Telnet)\n"
   printf       "M.  CSV - User(s) modification                  (Perl, SSH or Telnet)\n"

   printf   "\n"
   printf       "X.  EXIT\n\n"

   read MAINQ?"Choose the option: "
   case "$MAINQ" in
   L|l)  $lock_account;;
   RL|Rl|rl) $delete_locked_account;;
   G|g)  $audit_get_pw;;
   GA|Ga|ga)  $audit_get_pw_gr_sudo;;
   CD|Cd|cd)  $csv_userdel;;
   M|m)  $csv_usermod;;


   x|X)  mainmenu;;
   *)           reval_menu ;;
   esac
   reval_menu
}

csv_menu() {
   printf "\nUser Admin Menu Advanced(Multi-Proccesses: 10)\n"
   printf "*************************************\n"
   printf   "\n"
   printf       "G.  CSV Check id if exists on hosts                (Perl, SSH or Telnet)\n"
   printf       "D.  CSV Remove priv_access from user_alias(s)      (Perl, SSH or Telnet)\n"
   printf       "R.  CSV Run commands on hosts                      (Perl, SSH or Telnet)\n"

   printf   "\n"
   printf       "X.  EXIT\n\n"

   read MAINQ?"Choose the option: "
   case "$MAINQ" in
   G|g)  $csv_grep;;
   D|d)  $csv_del_sudo_alias;;
   R|r)  $csv_command;;


   x|X)  mainmenu;;
   *)           csv_menu ;;
   esac
   csv_menu
}

tools_menu() {
   printf "\nUser Admin Tools Menu \n"
   printf "*************************************\n"
   printf   "\n"
   printf       "N.  Record Non_personal ID                      (Perl)\n"
   printf       "G.  Password Generator                          (Perl)\n"
   printf       "S.  Encrypted Password Generator(linux)         (Perl)\n"
   printf   "\n"
   printf       "X.  EXIT\n\n"

   read MAINQ?"Choose the option: "
   case "$MAINQ" in
   N|n)  $non_personal_id_db;;
   G|g)  $password_generator;;
   S|s)  $shadow_generator;;

   x|X)  mainmenu;;
   *)           tools_menu ;;
   esac
   tools_menu
}

root_password_menu() {
   printf "\nUser Admin Menu For Root PW\n"
   printf "*************************************\n"
   printf   "\n"
   printf       "G.  Password Generator                          (Perl)\n"
   printf       "R.  CSV Root Password Reset                     (Perl, SSH or Telnet)\n"

   printf   "\n"
   printf       "X.  EXIT\n\n"

   read MAINQ?"Choose the option: "
   case "$MAINQ" in
   G|g)  $password_generator;;
   R|r)  $csv_update_root_password;;



   x|X)  mainmenu;;
   *)           root_password_menu ;;
   esac
   root_password_menu
}

mainmenu

