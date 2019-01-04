%% @author martin
-module(sudoku_solver).
-include_lib("eunit/include/eunit.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-compile(export_all).

-spec solve(Problem::list()) -> {term(), list()}.
solve(Problem) ->
	solve(Problem, _MaxTry = 100).

solve(Problem, MaxTry) ->
	io:format("Problem = ~p~n",[Problem]),
	solve(init(Problem), MaxTry, 1).

solve(Problem, MaxTry, Iteration) when Iteration < MaxTry ->
	Solution1 = eliminate_horizontal(Problem),
	Solution2 = eliminate_vertical(Solution1),
	Solution3 = eliminate_square(Solution2),
	%io:format("Current solution after ~p iteration(s): ~p~n", [Iteration, Solution3]),
	case {Solution3, length(lists:flatten(Solution3))} of
		{Problem, 81} -> % 9 x 9 = 81 digits if a solution is found, otherwise candidates makes the list grow larger. 
			{ok, Solution3};
		{Problem, _Length} ->
			{no_solution_found, Solution3};
		_ ->
			solve(Solution3, MaxTry, Iteration + 1)
	end;
solve(Solution, MaxTry, _Iteration) ->
	io:format("~p iterations were not enough to solve this problem.~n", [MaxTry]),
	io:format("Try to set a higher value:~n~p:solve(Problem, MaxTry)~nwhere MaxTry is larger than ~p~n", [?MODULE,MaxTry]),
	{no_solution_found, Solution}.
  

%% ====================================================================
%% Internal functions
%% ====================================================================
init(Rows) ->
	lists:map(fun init_row/1, Rows).

%% Takes a list of Digits and replace 0 with all possible values -> [1..9] 
init_row(Row) ->
	lists:map(fun(Digit) -> case Digit of
								0 -> lists:seq(1,9);
								Digit -> Digit
							end
			  end,
			  Row).

eliminate_horizontal(Solution) ->
	lists:map(fun reduce_candidates/1, Solution).

eliminate_vertical(Solution) ->
	Solution1 = transpose(Solution),
	Solution2 = lists:map(fun reduce_candidates/1, Solution1),
	Solution3 = transpose(Solution2),
	Solution3.

eliminate_square(Solution) ->
	Solution1 = transpose_squares_to_rows(Solution),
	Solution2 = lists:map(fun reduce_candidates/1, Solution1),
	Solution3 = transpose_squares_to_rows(Solution2),
	Solution3.

%% Remove candidates that are already assigned in a row
reduce_candidates(Row) ->
	AllreadyAssignedDigitsInRow = [Digit || Digit <- Row, is_integer(Digit)],
	reduce_candidates(Row, AllreadyAssignedDigitsInRow).

reduce_candidates([], _AllreadyAssignedDigitsInRow) ->
		[];
reduce_candidates(Row, []) ->
		Row;
reduce_candidates([Digit|Rest], AllreadyAssignedDigitsInRow) when is_integer(Digit) ->
	[Digit|reduce_candidates(Rest, AllreadyAssignedDigitsInRow)];
reduce_candidates([Candidates|Rest], AllreadyAssignedDigitsInRow) when is_list(Candidates) ->
	Item = Candidates -- AllreadyAssignedDigitsInRow,
	Item2 = case Item of
				[Digit]	-> Digit;
				List	-> List
			end,
	[Item2|reduce_candidates(Rest, AllreadyAssignedDigitsInRow)].

%% transpose is used to change format from list of rows to list of columns and back again
transpose([[]|_]) -> [];
transpose(M) ->
  [lists:map(fun hd/1, M) | transpose(lists:map(fun tl/1, M))].

%% transpose is used to change format from list of rows to list of squares (3x3) and back again
transpose_squares_to_rows([]) -> [];
transpose_squares_to_rows([[],[],[]|Rest]) -> transpose_squares_to_rows(Rest);
transpose_squares_to_rows([Row1,Row2,Row3|Rest]) ->
	{Row1Hd,Row1Tl} = lists:split(3, Row1),
	{Row2Hd,Row2Tl}	= lists:split(3, Row2),
	{Row3Hd,Row3Tl} = lists:split(3, Row3),
	NewRest = [Row1Tl,Row2Tl,Row3Tl|Rest],
	[Row1Hd ++ Row2Hd ++ Row3Hd|transpose_squares_to_rows(NewRest)].


%%% Test code
test_init_row() ->
	Row = [0,0,9,0,2,0,0,0,6],
	Result = [lists:seq(1,9),lists:seq(1,9),9,lists:seq(1,9),2,lists:seq(1,9),lists:seq(1,9),lists:seq(1,9),6],
	Result = init_row(Row).

-define(EASY_PROBLEM, [[0,0,9,0,2,0,0,0,6],
					   [8,0,0,5,0,4,0,7,0],
					   [3,0,0,0,6,0,0,1,0],
					   [6,8,7,0,0,2,1,3,0],
					   [0,0,0,3,1,8,0,0,0],
					   [0,9,3,4,0,0,8,2,5],
					   [0,2,0,0,8,0,0,0,7],
					   [0,3,0,6,0,5,0,0,1],
					   [5,0,0,0,9,0,6,0,0]]).

easy_problem() -> ?EASY_PROBLEM.

-define(EASY_SOLUTION,   [[4,7,9,8,2,1,3,5,6],
						 [8,6,1,5,3,4,9,7,2],
						 [3,5,2,7,6,9,4,1,8],
						 [6,8,7,9,5,2,1,3,4],
						 [2,4,5,3,1,8,7,6,9],
						 [1,9,3,4,7,6,8,2,5],
						 [9,2,6,1,8,3,5,4,7],
						 [7,3,8,6,4,5,2,9,1],
						 [5,1,4,2,9,7,6,8,3]]).

-define(MEDIUM_PROBLEM,   [[0,0,8,0,6,9,0,0,0],
				           [2,0,9,0,0,0,0,5,7],
				           [0,0,7,1,0,0,0,0,0],
				           [1,0,0,0,0,0,0,3,5],
				           [0,3,0,4,2,1,0,9,0],
				           [7,4,0,0,0,0,0,0,8],
				           [0,0,0,0,0,6,5,0,0],
				           [6,7,0,0,0,0,3,0,2],
				           [0,0,0,3,4,0,8,0,0]]).

medium_problem() -> ?MEDIUM_PROBLEM.

-define(MEDIUM_SOLUTION,[[3,5,8,7,6,9,2,4,1],
						 [2,1,9,8,3,4,6,5,7],
						 [4,6,7,1,5,2,9,8,3],
						 [1,9,2,6,7,8,4,3,5],
						 [8,3,5,4,2,1,7,9,6],
						 [7,4,6,5,9,3,1,2,8],
						 [9,8,3,2,1,6,5,7,4],
						 [6,7,4,9,8,5,3,1,2],
						 [5,2,1,3,4,7,8,6,9]]).

 
-define(HARD_PROBLEM, [[0,0,0,7,0,0,0,0,5],
					   [5,1,7,0,4,2,0,0,0],
					   [0,2,0,3,0,0,0,0,6],
					   [0,0,0,0,0,0,0,1,9],
					   [0,0,9,0,0,0,6,0,0],
					   [7,4,0,0,0,0,0,0,0],
					   [2,0,0,0,0,7,0,5,0],
					   [0,0,0,1,2,0,9,6,3],
					   [4,0,0,0,0,5,0,0,0]]).

hard_problem() -> ?HARD_PROBLEM.

%% Don't have a solution for this problem yet.
-define(HARD_SOLUTION, [[0,0,0,7,0,0,0,0,5],
					   [5,1,7,0,4,2,0,0,0],
					   [0,2,0,3,0,0,0,0,6],
					   [0,0,0,0,0,0,0,1,9],
					   [0,0,9,0,0,0,6,0,0],
					   [7,4,0,0,0,0,0,0,0],
					   [2,0,0,0,0,7,0,5,0],
					   [0,0,0,1,2,0,9,6,3],
					   [4,0,0,0,0,5,0,0,0]]).


solve_easy_test() ->
	?assertEqual({ok, ?EASY_SOLUTION}, solve(?EASY_PROBLEM)).

solve_medium_test() ->
	?assertEqual({ok, ?MEDIUM_SOLUTION}, solve(?MEDIUM_PROBLEM)).

solve_hard_test() ->
	?assertEqual({ok, ?HARD_SOLUTION}, solve(?HARD_PROBLEM)).

