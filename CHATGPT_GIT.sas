OPTION SPOOL;
proc import datafile='Z:\Users\stephen.mcawille\veramedimol-main-C999-VeraMedimol-Pilot01-re_template\C999\VeraMedimol\Pilot01\re_template_sandpit123\share\documents\api_key.csv'
    out=api_key_dataset
    dbms=csv replace;
run;

data null;
    set api_key_dataset;
    call symputx('api_key', api_key);
run;

/* Define the dataset of prompts with possible values for the 'Task' parameter */
data Prompts;
    length code $ 16 description $ 1024;
    do code="optimize","clean","efficient","fast","readable"; 
        description="I want you to act as a code optimizer in SAS. {Describe problem with current code, if possible.} Can you make the code {optimize/clean/efficient/fast/readable}? {Insert Code}";
        output;
    end;
    code="explain"; 
    description="I want you to act as a code explainer in SAS. I don't understand this function. Can you please explain what it does, and provide sample code? {Insert Code}";
    output;
    code="debug"; 
    description="I want you act as a code debugger in SAS, here is a piece of SAS code {Insert Code} — I am getting the following error {Insert Error}. What is the reason for the bug?";
    output;
run;

%macro chatgpt(api_key=,dataset=, print=true, out=, task=, insert_code=, describe_code=, insert_error=) / minoperator mindelimiter=' ';
    /* Use superq to avoid macro quoting issues */
    %let task = %superq(task);
    %let insert_code = %superq(insert_code);    
    %let describe_code = %superq(describe_code);
    %let insert_error = %superq(insert_error);
    %let out = %upcase(&out.);
    %let print = %upcase(&print.);

    /* Error checking */

    /* There must be an API key */
    %if(%bquote(&api_key.) =) %then %do;
        %put ERROR: No API key supplied.;
        %abort;
    %end;

    /* Print must be a valid value */
    %if(NOT (&print. IN TRUE FALSE YES NO 1 0 LOG)) %then %do;
        %put ERROR: Invalid value for print. Expected TRUE, FALSE, YES, NO, 1, 0, or LOG.;
        %abort;
    %end;

    /* Check that the Prompts dataset exists */
    %if NOT %sysfunc(exist(&dataset.)) %then %do;
        %put ERROR: Dataset &dataset. does not exist!;
        %goto EndOfMacro;
    %end;

    /* If the task parameter is missing, show help information */
    %if %superq(TASK) = %then %do;
        %put NOTE: This is a help info for macro &sysmacroname..;
        %put NOTE- The TASK parameter allows only the following values for actions:;
        options nosource;
        data _null_;
            set Prompts;
            by description notsorted;
            if first.description then
                put "NOTE- " @;
            put code @;
            if last.description then 
                put " is for: " / @7 description/;
        run;
        options nosource;
        %goto EndOfMacro;
    %end;

    /* Check that the specified task is valid */
    options nosource nonotes;
    proc sql noprint;
        select code into :list_of_codes separated by " " from &dataset.;
    quit;
    options source notes;

    %if NOT (%superq(TASK) in (&list_of_codes.)) %then %do;
        %put ERROR: The TASK parameter has an invalid value!;
        %goto EndOfMacro;
    %end;

    /* Print the prompt message */
    options nosource;
    data _null_;
        set Prompts;
        where code = symget('task');
        insert_code = symget('insert_code');
        insert_error = symget('insert_error');
        describe_code = symget('describe_code');
        length Prompt $ 32767;
        Prompt = prxchange('s/\{Describe problem with current code, if possible\.\}/'||strip(describe_code)||'/io', -1, description);
        Prompt = prxchange('s/\{Insert Code\}/'||strip(insert_code)||'/io', -1, Prompt);
        Prompt = prxchange('s/\{Insert Error\}/'||strip(insert_error)||'/io', -1, Prompt);
        Prompt = prxchange('s/\{optimize\/clean\/efficient\/fast\/readable\}/'||strip(code)||'/io', -1, Prompt);
        put "THE PROMPT:";
        put Prompt /;
    run;
    options nosource;

    /* If no output dataset is supplied, use __temp__ */
    %if(&out. =) %then %let outdata = __temp__;
    %else %let outdata = &out.;


    /* Body of the POST request */
    filename in temp;

  options nosource;
    data _null_;
    file in;
    put "{";
    put '"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": ' """&task.""" '}, {"role": "user", "content": ' """&insert_code.""" '},{"role": "user", "content": ' """&insert_error.""" '}, {"role": "user", "content": ' """&describe_code.""" '}]';
    put "}";
    run;


    /* Reference that file as IN= parm in PROC HTTP POST */
    filename resp "%sysfunc(getoption(WORK))/echo.json";

    /* Send the request and payload */
    proc http 
        method = "POST"
        url    = "https://api.openai.com/v1/chat/completions"
        ct     = "application/json"
        in     = in
        out    = resp;
        headers "Authorization" = "Bearer &api_key.";
    run;    
    

    /* Check the status code */
    %if(&SYS_PROCHTTP_STATUS_CODE. NE 200) %then %do;
        %put An error occurred. HTTP &SYS_PROCHTTP_STATUS_CODE.: &SYS_PROCHTTP_STATUS_PHRASE;
        %abort;
    %end;
 
    /* Tell SAS to parse the JSON response */
    libname response JSON fileref=resp;

    /* Format JSON in presentable format */
    data &outdata. ;
        set response.choices_message;
            do row=1 to max(1,countw(content,'0A'x));
                outvar=scan(content,row,'0A'x);
                output;
            end;
        drop content;
    run;  

/*    libname response clear;*/

    /* Output to either ODS or the log */
    %if(&print. IN TRUE YES 1) %then %do;
        proc report data= &outdata. ;
            column outvar;
            define outvar / display "" style(column)=[cellwidth=6in fontsize=10pt asis=ON];
        run;
    %end;
        %else %if(&print. = LOG) %then %do;
            data _null_;
                 rc = jsonpp('resp','log');
            run;
        %end;

    /* Remove temporary data */
    %if(&out. =) %then %do;
        proc datasets lib=work nolist;
            delete &outdata.;
        quit;
    %end;
%EndOfMacro:
%mend;

%chatgpt(api_key=&api_key.,dataset= work.prompts, print=true, out=, task= explain, insert_code={PROC DS2});
%chatgpt(api_key=&api_key.,dataset= work.prompts, print=true, out=, task= debug, insert_code={data test123; set sashelp.class run;}, insert_error=ERROR: File WORK.RUN.DATA does not exist.);
%chatgpt(api_key=&api_key.,dataset= work.prompts, print=true, out=, task= efficient, insert_code={data test123; set sashelp.class; run;}, describe_code= That data step works slow.);
