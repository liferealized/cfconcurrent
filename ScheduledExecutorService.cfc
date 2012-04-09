/**
* http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/ScheduledThreadPoolExecutor.html
*/
component extends="AbstractExecutorService" accessors="true" output="false"{

	property name="scheduledExecutor";
	property name="storedTasks" type="struct";

	public function init( String serviceName, maxConcurrent=0, objectFactory="#createObject('component', 'ObjectFactory').init()#" ){

		super.init( serviceName, objectFactory );
		structAppend( variables, arguments );
		if( maxConcurrent LTE 0 ){
			variables.maxConcurrent = getProcessorCount() + 1;
		}

		storedTasks = {};
		return this;
	}

	public function start(){
		variables.scheduledExecutor = objectFactory.createScheduledThreadPoolExecutor( maxConcurrent );

		//store the executor for sane destructability
		storeExecutor( "scheduledExecutor", variables.scheduledExecutor );

		return super.start();
	}

	public function scheduleAtFixedRate( id, task, initialDelay, period, timeUnit="seconds" ){

		var future = scheduledExecutor.scheduleAtFixedRate(
			objectFactory.createRunnableProxy( task ),
			initialDelay,
			period,
			objectFactory.getTimeUnitByName( timeUnit )
		);
		storeTask( id, task, future );
		return future;
	}

	public function scheduleWithFixedDelay( id, task, initialDelay, delay, timeUnit="seconds" ){
		var future = scheduledExecutor.scheduleWithFixedDelay(
			objectFactory.createRunnableProxy( task ),
			initialDelay,
			delay,
			objectFactory.getTimeUnitByName( timeUnit )
		);
		storeTask( id, task, future );
		return future;
	}

	package function storeTask( id, task, future ){

		lock name="storeScheduledTask_#serviceName#_#id#" timeout="2"{
			cancelTask( id );
			storedTasks[ id ] = { task = task, future = future };
		}

		return this;
	}

	/**
	* Returns a struct with keys 'task' and 'future'. The 'task' is the original object submitted to the executor.
		The 'future' is the <ScheduledFuture> object returned when submitting the task
	*/
	public function cancelTask( id ){
		if( structKeyExists( storedTasks, id ) ){
			var task = storedTasks[ id ];
			var future = task.future;
			future.cancel( true );
			scheduledExecutor.purge();
			structDelete( storedTasks, id );
			return task;
		}
	}

}