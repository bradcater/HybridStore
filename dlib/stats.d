module dlib.stats;

import dlib.config;
import dlib.json;
import std.string;

int STATS_TOTAL_QUERIES = 0;
int[char[]] STATS_COMMON_QUERIES;

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
