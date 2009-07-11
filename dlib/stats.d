module dlib.stats;

import dlib.config;
import dlib.json;
import std.string;

/**
    The number of queries parsed so far.
*/
int STATS_TOTAL_QUERIES = 0;

/**
    The common queries and their "counts".
*/
int[char[]] STATS_COMMON_QUERIES;

/**
    The algorithm used is not entirely accurate and performs well only when a
    few queries appear far more often than the rest. Briefly, each time a new
    query q_new is seen, for each query q_old that we are maintaining, if
    q_new == q_old, we increment its count by one; otherwise, we decrement its
    count by one. Any time a query's count reaches 0, we replace it with the
    next incoming query.
*/
void maintain_queries(char[] query)
{
    STATS_TOTAL_QUERIES += 1;
    if (STATS_COMMON_QUERIES.keys.length < QUERY_COUNT)
    {
        STATS_COMMON_QUERIES[query] = 1;
    } else {
        foreach (key; STATS_COMMON_QUERIES.keys)
        {
            if (query == key)
            {
                STATS_COMMON_QUERIES[key] += 1;
            } else {
                if (STATS_COMMON_QUERIES[key] == 0)
                {
                    STATS_COMMON_QUERIES.remove(key);
                    STATS_COMMON_QUERIES[query] = 1;
                } else {
                    STATS_COMMON_QUERIES[key] -= 1;
                }
            }
        }
    }
}

/**
    Formats the most common queries that we have been maintaining as human-
    readable (pretty) strings.
*/
char[] pretty_queries(int[char[]] queries)
{
    char[][char[]] s_queries;
    foreach (key; queries.keys)
    {
        s_queries[key] = format("%s", queries[key]);
    }
    s_queries["query_count"] = format("%s", STATS_TOTAL_QUERIES);
    return encode(s_queries,false);
}
