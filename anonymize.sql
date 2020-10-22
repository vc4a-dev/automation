/* empty large tables that are not very useful on other environments */
TRUNCATE wp_vc4a_email_log_events;
TRUNCATE wp_vc4a_email_log;

update wp_users
set user_login = concat_ws( '-', 'login', ID),
    user_nicename = concat_ws( '-', 'nicename', ID),
    user_email = concat_ws( '@', ID, 'vc4a.com' ),
    display_name = concat_ws( '-', 'display_name', ID),
    user_url = concat_ws('-', 'https://vc4a.com/members/user', ID)
where 1 = 1 AND user_email NOT LIKE '%@vc4a.com' AND user_email NOT LIKE '%@vc4africa.biz';

/*Users meta table*/
update wp_usermeta
set meta_value = concat_ws( '-', 'user-first_name', user_id )
where meta_key = 'first_name';

update wp_usermeta
set meta_value = concat_ws( '-', 'user-last_name', user_id )
where meta_key = 'last_name';

update wp_usermeta
set meta_value = concat_ws( '-', 'user-nickname', user_id )
where meta_key = 'nickname';

update wp_usermeta
set meta_value = concat_ws( '-', user_id, 'user_email@vc4a.com' )
where meta_key = 'billing_email';

update wp_usermeta
set meta_value = concat_ws( ' ', '+123', umeta_id, user_id )
where meta_key = 'billing_phone';

update wp_usermeta
set meta_value = concat_ws( '-', 'user-first_name', user_id )
where meta_key = 'billing_first_name';

update wp_usermeta
set meta_value = concat_ws( '-', 'user-last_name', user_id )
where meta_key = 'billing_last_name';

/*Woocommerce customer lookup table*/
update wp_6_wc_customer_lookup
set username = concat_ws( '-', 'user-name', user_id ),
    first_name = concat_ws( '-', 'user-first_name', user_id ),
    last_name = concat_ws( '-', 'user-last_name', user_id ),
    email = concat_ws( '-', user_id, 'user_email@vc4a.com' )
where 1 = 1;

/*BuddyPress xprofile table*/
update wp_bp_xprofile_data
set value = concat_ws( '-', 'user-name', user_id )
where field_id = 1;

update wp_bp_xprofile_data
set value = '1980-01-01 00:00:00'
where field_id = 668;

update wp_bp_xprofile_data
set value = concat_ws( '-', 'https://linkedin.com/user', user_id )
where field_id = 637;

update wp_bp_xprofile_data
set value = concat_ws( '-', 'https://twitter.com/user', user_id )
where field_id = 639;

/*Comments table*/
update wp_comments
set comment_author = concat_ws( '-', 'user-author', user_id ),
    comment_author_email = concat_ws( '-', user_id, 'user_email@vc4a.com' ),
    comment_author_url = concat_ws('-', 'https://vc4a.com/members/user', user_id )
where 1 = 1;

/*Signups table*/
update wp_signups
set user_login = concat_ws( '-', 'user', signup_id ),
    user_email = concat_ws( '-', signup_id, 'user_email@vc4a.com' ),
    meta = '' where 1 = 1;
