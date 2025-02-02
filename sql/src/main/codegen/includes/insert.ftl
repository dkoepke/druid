/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

// Using fully qualified name for Pair class, since Calcite also has a same class name being used in the Parser.jj
SqlNode DruidSqlInsert() :
{
  SqlNode insertNode;
  org.apache.druid.java.util.common.Pair<Granularity, String> partitionedBy = null;
  SqlNodeList clusteredBy = null;
}
{
  insertNode = SqlInsert()
  <PARTITIONED> <BY>
  partitionedBy = PartitionGranularity()
  [
    <CLUSTERED> <BY>
    clusteredBy = ClusterItems()
  ]
  {
    if (!(insertNode instanceof SqlInsert)) {
      // This shouldn't be encountered, but done as a defensive practice. SqlInsert() always returns a node of type
      // SqlInsert
      return insertNode;
    }
    SqlInsert sqlInsert = (SqlInsert) insertNode;
    return new DruidSqlInsert(sqlInsert, partitionedBy.lhs, partitionedBy.rhs, clusteredBy);
  }
}

SqlNodeList ClusterItems() :
{
  List<SqlNode> list;
  final Span s;
  SqlNode e;
}
{
  e = OrderItem() {
    s = span();
    list = startList(e);
  }
  (
    LOOKAHEAD(2) <COMMA> e = OrderItem() { list.add(e); }
  )*
  {
    return new SqlNodeList(list, s.addAll(list).pos());
  }
}

org.apache.druid.java.util.common.Pair<Granularity, String> PartitionGranularity() :
{
  SqlNode e = null;
  org.apache.druid.java.util.common.granularity.Granularity granularity = null;
  String unparseString = null;
}
{
  (
    <HOUR>
    {
      granularity = Granularities.HOUR;
      unparseString = "HOUR";
    }
  |
    <DAY>
    {
      granularity = Granularities.DAY;
      unparseString = "DAY";
    }
  |
    <MONTH>
    {
      granularity = Granularities.MONTH;
      unparseString = "MONTH";
    }
  |
    <YEAR>
    {
      granularity = Granularities.YEAR;
      unparseString = "YEAR";
    }
  |
    <ALL> <TIME>
    {
      granularity = Granularities.ALL;
      unparseString = "ALL TIME";
    }
  |
    e = Expression(ExprContext.ACCEPT_SUB_QUERY)
    {
      granularity = DruidSqlParserUtils.convertSqlNodeToGranularityThrowingParseExceptions(e);
      unparseString = e.toString();
    }
  )
  {
    return new org.apache.druid.java.util.common.Pair(granularity, unparseString);
  }
}
