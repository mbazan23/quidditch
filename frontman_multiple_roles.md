<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'      # byexample: +pass +timeout=30
>> Harness::init_test(self)             # byexample: +pass +timeout=30

>> require_relative "./lib/csp/frontman_adding_user.rb"
>> require_relative "./lib/shared/dcon_users.rb"


Echo and copy the management console IP address
$ echo $MC
<mc-ip>

Reset the users (delete any extra user from a previous test)
dshell> expert on                               # byexample: +pass
dshell> reset /config/global/access/users       # byexample: +pass
-->


## Create user multi role

As an administrator, an user can be created from the UI (Multiple roles selected):

```ruby
>> csp_login                    # byexample: +timeout=10
>> user_multi_role = DCONUser.new(role: ['analyst','readonly'])
>> frontman_add_user(user_multi_role)      # byexample: +timeout=30
Clicking on Setup
Clicking on Users
Clicking on Add
Inside new user modal, filling out the fields
Page has Save button: true
Username: [USER LOGIN]
User email: [USER LOGIN]@qa-hp-1.qa.atl.damballa
Name: [USER NAME]
Clicking on Save
```

Now, the user was created but it cannot log in yet because he has not
a valid password.


## Set a password by the administrator

We look for the user in the users configuration. Then just click in edit and click in change password:

```ruby
>> usercard = wait_until { find("#user-card-#{user_multi_role.login}") }   # byexample: +timeout=15
>> usercard.find('a.edit-user').click # this lets us edit the user
>> usercard.find('a.view-profile').click
>> wait_until { find("#user_unencrypted_password") }                    # byexample: +timeout=15
```

Set the password and Sign Out

```ruby
>> user_multi_role.password = "1234567"
>> fill_in('user[unencrypted_password]', with: user_multi_role.password)
>> fill_in('user[unencrypted_password_confirmation]', with: user_multi_role.password)
>> click_on 'Save'
>> click_on 'Sign Out'
```

<!--
We capture the username and password to use them later
>> puts user_multi_role.login
<user-login>

>> puts user_multi_role.password
<password>
-->

## We connect by ssh. The prompt is displayed, indicating the successful connection

```shell
$ sshpass -p '<password>' \
>         ssh -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' \
>         <user-login>@<mc-ip>                                                      # byexample: +paste 
<...>
<user-login>@<...>:/>.
```

<!--
Delete all users

dshell> expert on                               # byexample: -skip +pass
dshell> reset /config/global/access/users       # byexample: -skip +pass
dshell> expert off                              # byexample: -skip +pass
-->
